import Foundation

/// Minimal arbitrary-precision unsigned integer for DSA signature verification.
/// Internal representation: little-endian array of UInt limbs.
struct BigUInt: Equatable, Comparable, CustomStringConvertible {

    private(set) var limbs: [UInt]

    // MARK: - Initializers

    init() {
        self.limbs = [0]
    }

    init(_ value: UInt) {
        self.limbs = value == 0 ? [0] : [value]
    }

    init(_ value: Int) {
        precondition(value >= 0, "BigUInt cannot represent negative values")
        self.limbs = value == 0 ? [0] : [UInt(value)]
    }

    /// Initialize from big-endian Data bytes
    init(data: Data) {
        if data.isEmpty {
            self.limbs = [0]
            return
        }

        // Skip leading zeros
        var startIndex = 0
        while startIndex < data.count && data[data.startIndex + startIndex] == 0 {
            startIndex += 1
        }
        if startIndex == data.count {
            self.limbs = [0]
            return
        }

        let bytes = data.suffix(from: data.startIndex + startIndex)
        let limbSize = MemoryLayout<UInt>.size // 8 on 64-bit

        // Convert big-endian bytes to little-endian UInt limbs
        var result = [UInt]()
        var i = bytes.endIndex
        while i > bytes.startIndex {
            var limb: UInt = 0
            let limbStart = Swift.max(bytes.startIndex, i - limbSize)
            for j in limbStart..<i {
                limb = (limb << 8) | UInt(bytes[j])
            }
            result.append(limb)
            i = limbStart
        }

        self.limbs = result.isEmpty ? [0] : result
        normalize()
    }

    /// Initialize from limbs array (little-endian)
    private init(limbs: [UInt]) {
        self.limbs = limbs.isEmpty ? [0] : limbs
        normalize()
    }

    // MARK: - Properties

    var isZero: Bool {
        limbs.count == 1 && limbs[0] == 0
    }

    var isOdd: Bool {
        limbs[0] & 1 == 1
    }

    var bitLength: Int {
        if isZero { return 0 }
        let topLimb = limbs[limbs.count - 1]
        return (limbs.count - 1) * UInt.bitWidth + (UInt.bitWidth - topLimb.leadingZeroBitCount)
    }

    var description: String {
        if isZero { return "0" }
        // Convert to decimal string for debugging
        var result = ""
        var temp = self
        let ten = BigUInt(10)
        while !temp.isZero {
            let (q, r) = temp.divmod(ten)
            result = "\(r.limbs[0])" + result
            temp = q
        }
        return result.isEmpty ? "0" : result
    }

    // MARK: - Normalization

    private mutating func normalize() {
        while limbs.count > 1 && limbs.last == 0 {
            limbs.removeLast()
        }
    }

    // MARK: - Comparison

    static func == (lhs: BigUInt, rhs: BigUInt) -> Bool {
        lhs.limbs == rhs.limbs
    }

    static func < (lhs: BigUInt, rhs: BigUInt) -> Bool {
        if lhs.limbs.count != rhs.limbs.count {
            return lhs.limbs.count < rhs.limbs.count
        }
        for i in stride(from: lhs.limbs.count - 1, through: 0, by: -1) {
            if lhs.limbs[i] != rhs.limbs[i] {
                return lhs.limbs[i] < rhs.limbs[i]
            }
        }
        return false // equal
    }

    // MARK: - Addition

    static func + (lhs: BigUInt, rhs: BigUInt) -> BigUInt {
        let maxCount = Swift.max(lhs.limbs.count, rhs.limbs.count)
        var result = [UInt]()
        result.reserveCapacity(maxCount + 1)
        var carry: UInt = 0

        for i in 0..<maxCount {
            let a = i < lhs.limbs.count ? lhs.limbs[i] : 0
            let b = i < rhs.limbs.count ? rhs.limbs[i] : 0
            let (sum1, overflow1) = a.addingReportingOverflow(b)
            let (sum2, overflow2) = sum1.addingReportingOverflow(carry)
            result.append(sum2)
            carry = (overflow1 ? 1 : 0) + (overflow2 ? 1 : 0)
        }
        if carry > 0 {
            result.append(carry)
        }
        return BigUInt(limbs: result)
    }

    // MARK: - Subtraction (assumes lhs >= rhs)

    static func - (lhs: BigUInt, rhs: BigUInt) -> BigUInt {
        precondition(lhs >= rhs, "BigUInt subtraction would result in negative value")
        var result = [UInt]()
        result.reserveCapacity(lhs.limbs.count)
        var borrow: UInt = 0

        for i in 0..<lhs.limbs.count {
            let a = lhs.limbs[i]
            let b = i < rhs.limbs.count ? rhs.limbs[i] : 0
            let (diff1, overflow1) = a.subtractingReportingOverflow(b)
            let (diff2, overflow2) = diff1.subtractingReportingOverflow(borrow)
            result.append(diff2)
            borrow = (overflow1 ? 1 : 0) + (overflow2 ? 1 : 0)
        }
        return BigUInt(limbs: result)
    }

    // MARK: - Multiplication

    static func * (lhs: BigUInt, rhs: BigUInt) -> BigUInt {
        if lhs.isZero || rhs.isZero { return BigUInt(0) }

        var result = [UInt](repeating: 0, count: lhs.limbs.count + rhs.limbs.count)

        for i in 0..<lhs.limbs.count {
            var carry: UInt = 0
            for j in 0..<rhs.limbs.count {
                let (high, low) = lhs.limbs[i].multipliedFullWidth(by: rhs.limbs[j])
                let (sum1, o1) = result[i + j].addingReportingOverflow(low)
                let (sum2, o2) = sum1.addingReportingOverflow(carry)
                result[i + j] = sum2
                carry = high &+ (o1 ? 1 : 0) &+ (o2 ? 1 : 0)
            }
            result[i + rhs.limbs.count] = carry
        }
        return BigUInt(limbs: result)
    }

    // MARK: - Division & Modulo

    /// Returns (quotient, remainder)
    func divmod(_ divisor: BigUInt) -> (BigUInt, BigUInt) {
        precondition(!divisor.isZero, "Division by zero")

        if self < divisor {
            return (BigUInt(0), self)
        }
        if divisor.limbs.count == 1 {
            return divmodSingleLimb(divisor.limbs[0])
        }
        return divmodKnuth(divisor)
    }

    /// Single-limb division
    private func divmodSingleLimb(_ divisor: UInt) -> (BigUInt, BigUInt) {
        var quotient = [UInt](repeating: 0, count: limbs.count)
        var remainder: UInt = 0

        for i in stride(from: limbs.count - 1, through: 0, by: -1) {
            let (q, r) = divisor.dividingFullWidth((high: remainder, low: limbs[i]))
            quotient[i] = q
            remainder = r
        }
        return (BigUInt(limbs: quotient), BigUInt(remainder))
    }

    /// Knuth's Algorithm D for multi-limb division
    private func divmodKnuth(_ divisor: BigUInt) -> (BigUInt, BigUInt) {
        let n = divisor.limbs.count
        let m = self.limbs.count - n

        // Normalize: shift so that the leading digit of divisor >= base/2
        let shift = divisor.limbs[n - 1].leadingZeroBitCount
        let u = self << shift
        let v = divisor << shift

        // Ensure u has m+n+1 limbs
        var uLimbs = u.limbs
        while uLimbs.count <= m + n {
            uLimbs.append(0)
        }
        let vLimbs = v.limbs

        var quotient = [UInt](repeating: 0, count: m + 1)

        for j in stride(from: m, through: 0, by: -1) {
            // Estimate quotient digit
            let twoDigit: (high: UInt, low: UInt) = (uLimbs[j + n], uLimbs[j + n - 1])
            var qHat: UInt
            var rHat: UInt

            if twoDigit.high >= vLimbs[n - 1] {
                qHat = UInt.max
                rHat = twoDigit.low &+ vLimbs[n - 1]
                // If rHat overflows, the refinement loop won't improve, so skip
                if rHat < vLimbs[n - 1] {
                    // overflow occurred, skip refinement
                    quotient[j] = qHat
                    // Do multiply-subtract below
                } else {
                    // no overflow but still need refinement
                }
            } else {
                (qHat, rHat) = vLimbs[n - 1].dividingFullWidth(twoDigit)
            }

            // Refine estimate
            if !(twoDigit.high >= vLimbs[n - 1] && rHat < vLimbs[n - 1]) {
                while true {
                    let (prodHigh, prodLow) = qHat.multipliedFullWidth(by: n >= 2 ? vLimbs[n - 2] : 0)
                    if prodHigh > rHat || (prodHigh == rHat && prodLow > uLimbs[j + n - 2]) {
                        qHat -= 1
                        let (newRHat, overflow) = rHat.addingReportingOverflow(vLimbs[n - 1])
                        if overflow { break }
                        rHat = newRHat
                    } else {
                        break
                    }
                }
            }

            // Multiply and subtract using unsigned arithmetic only
            // We compute u[j..j+n] -= qHat * v[0..n]
            // Track borrow as a UInt
            var carry: UInt = 0  // carry from multiplication
            var borrow: UInt = 0 // borrow from subtraction
            for i in 0..<n {
                let (prodHigh, prodLow) = qHat.multipliedFullWidth(by: vLimbs[i])
                // product limb = prodLow + carry (may produce new carry)
                let (productLow, carryOverflow) = prodLow.addingReportingOverflow(carry)
                carry = prodHigh &+ (carryOverflow ? 1 : 0)

                // u[j+i] -= productLow (may produce borrow)
                let (diff1, borrow1) = uLimbs[j + i].subtractingReportingOverflow(productLow)
                let (diff2, borrow2) = diff1.subtractingReportingOverflow(borrow)
                uLimbs[j + i] = diff2
                borrow = (borrow1 ? 1 : 0) &+ (borrow2 ? 1 : 0)
            }
            // Handle final position
            let negative = uLimbs[j + n] < carry &+ borrow
            uLimbs[j + n] = uLimbs[j + n] &- carry &- borrow

            quotient[j] = qHat

            // If we subtracted too much, add back
            if negative {
                quotient[j] -= 1
                var addCarry: UInt = 0
                for i in 0..<n {
                    let (sum, o) = uLimbs[j + i].addingReportingOverflow(vLimbs[i])
                    let (sum2, o2) = sum.addingReportingOverflow(addCarry)
                    uLimbs[j + i] = sum2
                    addCarry = (o ? 1 : 0) + (o2 ? 1 : 0)
                }
                uLimbs[j + n] &+= addCarry
            }
        }

        // Denormalize remainder
        let remainder = BigUInt(limbs: Array(uLimbs.prefix(n))) >> shift
        return (BigUInt(limbs: quotient), remainder)
    }

    static func / (lhs: BigUInt, rhs: BigUInt) -> BigUInt {
        lhs.divmod(rhs).0
    }

    static func % (lhs: BigUInt, rhs: BigUInt) -> BigUInt {
        lhs.divmod(rhs).1
    }

    // MARK: - Bit Shifting

    static func << (lhs: BigUInt, rhs: Int) -> BigUInt {
        if rhs == 0 || lhs.isZero { return lhs }
        let limbShift = rhs / UInt.bitWidth
        let bitShift = rhs % UInt.bitWidth

        var result = [UInt](repeating: 0, count: lhs.limbs.count + limbShift + 1)
        if bitShift == 0 {
            for i in 0..<lhs.limbs.count {
                result[i + limbShift] = lhs.limbs[i]
            }
        } else {
            var carry: UInt = 0
            for i in 0..<lhs.limbs.count {
                let shifted = lhs.limbs[i] << bitShift
                result[i + limbShift] = shifted | carry
                carry = lhs.limbs[i] >> (UInt.bitWidth - bitShift)
            }
            result[lhs.limbs.count + limbShift] = carry
        }
        return BigUInt(limbs: result)
    }

    static func >> (lhs: BigUInt, rhs: Int) -> BigUInt {
        if rhs == 0 || lhs.isZero { return lhs }
        let limbShift = rhs / UInt.bitWidth
        let bitShift = rhs % UInt.bitWidth

        if limbShift >= lhs.limbs.count { return BigUInt(0) }

        let remaining = lhs.limbs.count - limbShift
        var result = [UInt](repeating: 0, count: remaining)
        if bitShift == 0 {
            for i in 0..<remaining {
                result[i] = lhs.limbs[i + limbShift]
            }
        } else {
            for i in 0..<remaining {
                result[i] = lhs.limbs[i + limbShift] >> bitShift
                if i + limbShift + 1 < lhs.limbs.count {
                    result[i] |= lhs.limbs[i + limbShift + 1] << (UInt.bitWidth - bitShift)
                }
            }
        }
        return BigUInt(limbs: result)
    }

    // MARK: - Modular Arithmetic

    /// Modular exponentiation using square-and-multiply (Montgomery-style)
    static func modPow(_ base: BigUInt, _ exp: BigUInt, _ mod: BigUInt) -> BigUInt {
        precondition(!mod.isZero, "Modulus cannot be zero")
        if mod == BigUInt(1) { return BigUInt(0) }

        var result = BigUInt(1)
        var base = base % mod
        var exp = exp

        while !exp.isZero {
            if exp.isOdd {
                result = (result * base) % mod
            }
            exp = exp >> 1
            if !exp.isZero {
                base = (base * base) % mod
            }
        }
        return result
    }

    /// Modular inverse using extended Euclidean algorithm.
    /// Returns nil if inverse doesn't exist (gcd(a, mod) != 1)
    static func modInverse(_ a: BigUInt, _ mod: BigUInt) -> BigUInt? {
        precondition(!mod.isZero, "Modulus cannot be zero")

        if a.isZero { return nil }

        // Extended GCD using signed representation
        // We track coefficients as (positive: BigUInt, negative: Bool)
        var old_r = a % mod
        var r = mod
        var old_s: BigUInt = BigUInt(1)
        var s: BigUInt = BigUInt(0)
        var old_s_neg = false
        var s_neg = false

        while !r.isZero {
            let (quotient, remainder) = old_r.divmod(r)

            old_r = r
            r = remainder

            // new_s = old_s - quotient * s
            let qs = quotient * s
            let new_s: BigUInt
            let new_s_neg: Bool
            if old_s_neg == s_neg {
                // same sign: old_s - q*s
                if old_s >= qs {
                    new_s = old_s - qs
                    new_s_neg = old_s_neg
                } else {
                    new_s = qs - old_s
                    new_s_neg = !old_s_neg
                }
            } else {
                // different signs: old_s + q*s (since subtracting negative = adding)
                new_s = old_s + qs
                new_s_neg = old_s_neg
            }

            old_s = s
            old_s_neg = s_neg
            s = new_s
            s_neg = new_s_neg
        }

        // GCD must be 1
        if old_r != BigUInt(1) { return nil }

        if old_s_neg {
            return mod - (old_s % mod)
        } else {
            return old_s % mod
        }
    }
}
