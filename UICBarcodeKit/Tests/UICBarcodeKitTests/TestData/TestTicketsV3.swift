import Foundation

/// Test ticket data from Java test files (src/test/java/org/uic/barcode/ticket/api/test/testtickets/)
/// These hex strings are extracted directly from the Java getEncodingHex() methods
/// for use in Swift decode tests that mirror the Java tests.
public enum TestTicketsV3 {

    // MARK: - OpenTicket Tests

    /// From OpenTestComplexTicketV3.java
    /// Contains: IssuingData, TravelerData, OpenTicketData with VatDetail and IncludedAddOns,
    /// StationPassageData, ControlData, ExtensionData
    public static let openTicketComplexHex =
        "7804404004B14374F3E7D72F2A9979F4A13A90086280B4001044A6F686E03446" +
        "F770562C99B46B01106E797769DFC81DB5E51DC9BDD5C0094075A2560282DA10" +
        "00000101C0101C4F11804281A4D5891EA450E6F70656E5469636B6574496E666" +
        "F0140AD06021B8090020080B23E8013E8100B10008143D09003D1C8787B4B731" +
        "B63AB232B2103A34B1B5B2BA090110081DC185CDCD859D94042505B5CDD195C9" +
        "9185B4B780BDA60100402C800131B200ADC2EAC588C593466D5C366E089E8A84" +
        "84074275204E9979F428100B10282DA01640507B40"

    // MARK: - Pass Tests

    /// From PassComplexTicketV3.java
    /// Contains: IssuingData, TravelerData, PassData with TrainValidity and VatDetail,
    /// StationPassageData, ControlData, ExtensionData
    public static let passComplexHex =
        "7804404004B14374F3E7D72F2A9979F4A13A90086280B4001044A6F686E03446" +
        "F770562C99B46B01106E797769DFC81DB5E51DC9BDD5C00940762CDA0282DA1A" +
        "8EB1700E04075BCD1523AC021E8AEAE4C2D2D8408CD8CAF0A0C2E6E617D0027D" +
        "05A03E8013E80209A258B4240990C902091302271001C4F11804281A4D5891EA" +
        "45097061737320696E666F120220103B830B9B9B0B3B28084A0B6B9BA32B9323" +
        "0B696F017B4C0200805900026364015B85D58B118B268CDAB86CDC113D150908" +
        "0E84EA409D32F3E850201620505B402C80A0F680"

    // MARK: - Countermark Tests

    /// From CountermarkTestComplexTicketV3.java
    /// Contains: IssuingData, TravelerData, CountermarkData, ControlData, ExtensionData
    public static let countermarkComplexHex =
        "7804404004B14374F3E7D72F2A9979F4A13A90086280B4001044A6F686E03446" +
        "F770562C99B46B01106E797769DFC81DB5E51DC9BDD5C004300002021058B84B" +
        "3B937BAB82730B6B28108240210000F11F08000788FC100040800440000B73C2" +
        "00005B9F0100088000035F8400001AFE08000789000203E720040201640200C8" +
        "042D8DBDD5B9D195C93585C9AD300802016400098D90056E17562C462C9A336A" +
        "E1B37044F45424203A13A90274CBCFA140805881416D00B20283DA"

    // MARK: - Delay Tests

    /// From DelayTestTicketV3.java
    /// Contains: IssuingData, TravelerData, DelayConfirmation, ControlData, ExtensionData
    public static let delayConfirmationHex =
        "780440A3E5DD4374F3E7D72F2A9979F4A13A90086200B4001044A6F686E03446F77" +
        "0562C99B46B01108CBB786CDFE72E50116AE4C130614494C593368D405901816" +
        "FA1E848001E009201802EA35350B4821B893232B630BC9031B7B73334B936B0B" +
        "A34B7B7240100402C800131B20100B10282DA01640507B4"

    // MARK: - Voucher Tests

    /// From VoucherTestTicketV3.java
    /// Contains: IssuingData, TravelerData, VoucherData, ControlData, ExtensionData
    public static let voucherHex =
        "780440A3E4B14374F3E7D72F2A9979F4A13A90086200B4001044A6F686" +
        "E03446F770562C99B46B01108CBB786CDFE72E50108928260C39115" +
        "8B266D1A86C39F1A3458B360C391267450600830040807D0398DBD9" +
        "999959481D9BDD58DA195C9200802016400098D900805881416D00B" +
        "20283DA"

    // MARK: - Station Passage Tests

    /// From StationPassageTestTicketV3.java
    /// Contains: IssuingData, TravelerData, StationPassageData, ControlData, ExtensionData
    public static let stationPassageHex =
        "7804404004B14374F3E7D72F2A9979F4A13A90086280B4001044A6F686E03446" +
        "F770562C99B46B01106E797769DFC81DB5E51DC9BDD5C00448088B40EE0C2E" +
        "6E6C2CECA021282DAE6E8CAE4C8C2DA5D000019F40082A60100402C800131B" +
        "20081013A65E7D00805881416D00B20283DA"

    // MARK: - Parking Tests

    /// From ParkingTestTicketV3.java
    /// Contains: IssuingData, TravelerData, ParkingGroundData, ControlData, ExtensionData
    public static let parkingHex =
        "780440A3E5DD4374F3E7D72F2A9979F4A13A90086200B400104" +
        "4A6F686E03446F770562C99B46B01108CBB786CDFE72E501" +
        "0EA05604C187222B164CDA3506A0D1BB664CD70008DA830B" +
        "935B4B73390233930B735B33AB93A1026B0B4B7102BB2B9B" +
        "A01BD090087B7BABA3237B7B9103830B935B4B73385C182B" +
        "62455AC593368D40807D1200802016400098D90080588141" +
        "6D00B20283DA0"

    // MARK: - Car Carriage Reservation Tests

    /// From CarCarriageReservationTestTicketV3.java
    /// Contains: IssuingData, TravelerData, CarCarriageReservationData, ControlData, ExtensionData
    public static let carCarriageReservationHex =
        "7804404004B14374F3E7D72F2A9979F4A13A90086280B4001" +
        "044A6F686E03446F770562C99B46B01106E797769DFC81" +
        "DB5E51DC9BDD5C0040AE43A8D6E9C02F60B0007D01802F" +
        "27C7BC4540318120AD06B9B832B1B4B0B6103A3930B4B7" +
        "3DCC50061A8001326204D1884C188B62455AC593309896" +
        "16C184B58B266639429A502086E127002802902698C2E4" +
        "CECA4086C2E4408CEAD8D8408CC2E4CA0460720389E230" +
        "0850349AB123D48A18C6C2E440C6C2E4E4D2C2CECA9004" +
        "0100B20004C6C80402C40A0B680590141ED00"

    // MARK: - All Elements Test

    /// From AllElementsTestTicketV3.java
    /// Comprehensive test with all possible FCB elements
    public static let allElementsHex =
        "7BFFE0000058FCFF016204004B008DCC2DACB69D28D06E9E7CFAE5E5532F3E94" +
        "275201620505B402F606C5933010C880230390300DDD50E02FFFFC1129BDA1B8" +
        "1931A5D1D1B1940D11BDDC158B266D1A824A89529D4344440D12D456B9EA0118" +
        "1C805FA21906519804C04041B9E5DDA77F28B381DB5E51DC9BDD5C03003FFFFF" +
        "FFFBF81181C82B164CDA3501863862C18B266D1AB66EE1C828953DD768ADB9F0" +
        "564CDA356DFFFE0CC593368D5B000C03544756054C7972696143DCC5003B862C" +
        "183060C5E848041DC3160C18306412825AA6A882A8929E9C12845AA6A882A892" +
        "9E9D67C054004602086E127008118B070C0118B170C4283F0366C6082B362B5A" +
        "370657696E646F77020366C6081B3630808787FE06CD8C10566C56B46E0CAED2" +
        "DCC8DEEE0406CD8C10366C61010F0FFC0D9B1820ACD8AD68DC195DA5B991BDDC" +
        "080D9B18206CD8C2021E1F7F0189881BC3BBD01BC3BBD01BC3BBD390028F9880" +
        "4FFC7F760200FE80001E80D8B2660001D206C99B401410142EC0E31012DD000A" +
        "40137641898CAC2E6EAE4CA408CC2E4CA02FFC268823164CDA010B1702356CDD" +
        "C043A32B9BA31B0B93200BD8106C0023368D5B00B201B160C008C0E40713C460" +
        "10A069356247A9164094101383499F12455AC4CC6E0D62C449156B143205B932" +
        "B9B2B93B30BA34B7B700B10282DA780BD81D6895812A45A7500A0B682FFFFFFF" +
        "FB780BD81B164CC16000FA5A0C70C583164CDA356CDDC390600BC9F1EF115B73" +
        "E0AC99B46ADBFFFC198B266D1AB600C60482B41AE6E0CAC6D2C2D840E8E4C2D2" +
        "DC9EE62801DC3160C183062F424020EE18B060C183209412D53544154494F4E0" +
        "9422D53544154494F4E0264C409A317F0189881BC3BBD01BC3BBD01BC3BBD213" +
        "0622D89156B164CC262585B0612D62C999D1CA4534A0410DC24E01023160E180" +
        "23162E18805005204D3185C99D94810D85C88119D5B1B0811985C99408C0E407" +
        "13C46010A069356247A914318D85C8818D85C9C9A5859D9405881416D027FFFF" +
        "FFFFF83005E4F8F788A863862C18B266D1AB66EE1CDB9F0564CDA356DFFFE0CC" +
        "593368D5B0086008693DCC5003B862C183060C5E848041DC3160C18306412825" +
        "AA6A882A8929E9C12845AA6A882A8929E9C228CE4DEDA408240E8DE408440ECD" +
        "2C240860A209E0860003C47C0CC593368D5A88000788FC100040800440000B73" +
        "C200005B9F0100088000035F8400001AFE08000789000203E701150200D601D4" +
        "08035807527FF086E08C5838608001344118B266D00024A01193368D40C07890" +
        "00805900803200A0B681A24568DD8B137FC21B823160E180100B201006420004" +
        "D10462C99B40009280464CDA350301E2400FF81181C82B164CDA3501D9F00F73" +
        "1400EE18B060C18317A12010770C583060C1904A096A9AA20AA24A7A704A116A" +
        "9AA20AA24A7A720008C0E40C0377540808C0E40C03775408C0E40C037755FEF7" +
        "31400EE18B060C18317A12010770C583060C1904A096A9AA20AA24A7A704A116" +
        "A9AA20AA24A7A7033932BA3AB93700938204370462C1C3040402C80401910AC0" +
        "078B9D9F8C04010105040821B849C020462C1C300462C5C310200D601D408035" +
        "80750100A00A409A630B933B29021B0B910233AB636102330B93281181C80827" +
        "88C1CDEE0CADCA8D2C6D6CAE892DCCCDE02FF5BFFDB9F0564CDA356DFFFE0CC5" +
        "93368D5B00860086A0120040101647D0027D024102086E127008118B070C0118" +
        "B170C40803580750200D601D40402802902698C2E4CECA4086C2E4408CEAD8D8" +
        "408CC2E4CA1ED2DCC6D8EAC8CAC840E8D2C6D6CAE804A5812A402C40A0B69010" +
        "129604A900B10282DA06FFBFFFFFC1802F27C7BC45431C3160C593368D5B3770" +
        "E6DCF82B266D1AB6FFFF0662C99B46AD8043D15D5C985A5B08119B195E14185C" +
        "DCC2FA1E809F43DC05F7D0F404FA1E80806012052D01F4009F40104D12C5A041" +
        "204C86481048981043709380408C58386008C58B8620410DC24E01023160E180" +
        "23162E1881006B00EA0401AC03A8090020080B200805005204D3185C99D94810" +
        "D85C88119D5B1B0811985C994089C400713C46010A069356247A91425C185CDC" +
        "C81A5B999BC05881416D047FE18E18B062C99B46AD9BB8720C01793E3DE22B6E" +
        "7C361CF8D1A2C59B061C8933A2FFFF833164CDA356C0C0106008100FA007A0E6" +
        "36F6666656520766F756368657201620505B415FFF0084008C59336810464CDA" +
        "350301E240FD0100814407042920A4A628262AA980808267DFB3201008080810" +
        "0B10282DA0CFFFFFFFE18E18B062C99B46AD9BB8720C01793E3DE22B6E7C1593" +
        "368D5B7FFF833164CDA356C18E18B062C99B46AD9BB8720C01793E3DE22A162E" +
        "12CEE4DEEAE09CC2DACA9EE62801DC3160C183062F424020EE18B060C1832094" +
        "12D53544154494F4E09422D53544154494F4E1146726F6D204120746F2042207" +
        "66961204301107C0430001E23E0662C99B46AD440003C47E0800204002200005" +
        "B9E100002DCF808004400001AFC200000D7F040003C48001043709380408C583" +
        "86008C58B8620407CE022A7FBDCC5003B862C183060C5E848041DC3160C18306" +
        "412825AA6A882A8929E9C12845AA6A882A8929E9C0CE4CAE8EAE4DC024E0810D" +
        "C118B170C50100B201006442B001E2E767E3040821B849C020462C1C300462C5" +
        "C310200D601D40803580750B636F756E7465724D61726B01620505B41DFEFF0C" +
        "70C583164CDA356CDDC390600BC9F1EF115039305ADC372B73E0AC99B46ADBFF" +
        "FC198B266D1AB603699F08DA830B935B4B73390233930B735B33AB93A1026B0B" +
        "4B7102BB2B9BA01BD0900839C18181818181887B7BABA3237B7B9103830B935B" +
        "4B733823632B33A05C182B62455AC593368D40807D00713C46010A069356247A" +
        "91405881416D087FFC31C3160C593368D5B3770E41802F27C7BC456DCF82B266" +
        "D1AB6FFFF0662C99B46AD80000010020D0703C0821B849C020462C1C300462C5" +
        "C31078405881416D097F7FFC31C3160C593368D5B3770E41802F27C7BC456DCF" +
        "82B266D1AB6FFFF0662C99B46AD81DC185CDCD859D94040DF47D04040E0CDA60" +
        "21282DAE6E8CAE4C8C2DA0206FA3E820207066D30109416D7374657264616D2E" +
        "8001E819F43D010501620505B42805881416D0B7FB709830A24A62C99B46A046" +
        "07202C806C58300605BE8B4F42400071254507802FC059712545A80C01751A9A" +
        "85A406B0B2B4113225789569346A10DC164C58D22A893232B630BC9031B7B733" +
        "34B936B0BA34B7B700B10282DA7E02FFC268823164CDA010B1702356CDDC043A" +
        "32B9BA31B0B93200BD8106C0023368D5B00B201B160C0010C1900EC6DEDCE8E4" +
        "DED802FC059712545A80C01751A9A85A406B0B2B4113225789569346A10DC164" +
        "C58D22A80B10282DA0201620505B402C80A0F680"

    // MARK: - Helper Functions

    /// Convert hex string to Data
    public static func hexToData(_ hex: String) -> Data {
        let cleanHex = hex.replacingOccurrences(of: " ", with: "")
                          .replacingOccurrences(of: "\n", with: "")
        var data = Data()
        var index = cleanHex.startIndex
        while index < cleanHex.endIndex {
            let nextIndex = cleanHex.index(index, offsetBy: 2)
            if let byte = UInt8(cleanHex[index..<nextIndex], radix: 16) {
                data.append(byte)
            }
            index = nextIndex
        }
        return data
    }

    /// Get Data for openTicketComplexHex
    public static var openTicketComplexData: Data {
        return hexToData(openTicketComplexHex)
    }

    /// Get Data for passComplexHex
    public static var passComplexData: Data {
        return hexToData(passComplexHex)
    }

    /// Get Data for countermarkComplexHex
    public static var countermarkComplexData: Data {
        return hexToData(countermarkComplexHex)
    }

    /// Get Data for delayConfirmationHex
    public static var delayConfirmationData: Data {
        return hexToData(delayConfirmationHex)
    }

    /// Get Data for voucherHex
    public static var voucherData: Data {
        return hexToData(voucherHex)
    }

    /// Get Data for stationPassageHex
    public static var stationPassageData: Data {
        return hexToData(stationPassageHex)
    }

    /// Get Data for parkingHex
    public static var parkingData: Data {
        return hexToData(parkingHex)
    }

    /// Get Data for carCarriageReservationHex
    public static var carCarriageReservationData: Data {
        return hexToData(carCarriageReservationHex)
    }

    /// Get Data for allElementsHex
    public static var allElementsData: Data {
        return hexToData(allElementsHex)
    }
}

// MARK: - Expected Values from Java Tests

/// Expected values for OpenTicket Complex V3 (from OpenTestComplexTicketV3.java)
public enum OpenTicketV3Expected {
    // IssuingData
    public static let issuingYear = 2018
    public static let issuingDay = 1
    public static let issuingTime = 600
    public static let issuerPNR = "issuerTestPNR"
    public static let specimen = true
    public static let securePaperTicket = false
    public static let activated = true
    public static let issuedOnLine = 12

    // TravelerData
    public static let groupName = "myGroup"
    public static let firstName = "John"
    public static let secondName = "Dow"
    public static let idCard = "12345"
    public static let ticketHolder = true
    public static let customerStatusDescr = "senior"

    // ControlData
    public static let controlInfoText = "cd"
    public static let trailingCardIdNum = 100

    // OpenTicketData
    public static let returnIncluded = false
    public static let classCode = 1 // first
    public static let openTicketInfoText = "openTicketInfo"

    // VatDetail
    public static let vatCountry = 80
    public static let vatPercentage = 70
    public static let vatAmount = 10
    public static let vatId = "IUDGTE"

    // IncludedAddOn
    public static let includedProductOwner = 1080
    public static let includedClassCode = 2 // second
    public static let includedInfoText = "included ticket"
    public static let zoneId = 100
    public static let tariffPassengers = 2
    public static let tariffPassengerType = 0 // adult
    public static let routeFromStation = 8000001
    public static let routeToStation = 8010000
    public static let includedValidFromDay = 0
    public static let includedValidFromTime = 1000
    public static let includedValidUntilDay = 1
    public static let includedValidUntilTime = 1000

    // StationPassage
    public static let passageProductName = "passage"
    public static let passageStation = "Amsterdam"
    public static let passageValidFromDay = 0
    public static let passageNumberOfDaysValid = 123

    // TicketLink
    public static let ticketLinkReferenceIA5 = "UED12435867"
    public static let ticketLinkIssuerName = "OEBB"
    public static let ticketLinkIssuerPNR = "PNR"
    public static let ticketLinkProductOwnerIA5 = "test"

    // Token
    public static let tokenProviderIA5 = "VDV"
    public static let tokenData = Data([0x82, 0xDA])

    // Extension
    public static let extension1Id = "1"
    public static let extension1Data = Data([0x82, 0xDA])
    public static let extension2Id = "2"
    public static let extension2Data = Data([0x83, 0xDA])
}

/// Expected values for Pass Complex V3 (from PassComplexTicketV3.java)
public enum PassV3Expected {
    // IssuingData (same as OpenTicket)
    public static let issuingYear = 2018
    public static let issuingDay = 1
    public static let issuerPNR = "issuerTestPNR"
    public static let specimen = true
    public static let activated = true
    public static let issuedOnLine = 12

    // PassData
    public static let referenceNum = 123456789
    public static let productOwnerNum = 4567
    public static let passDescription = "Eurail FlexPass"
    public static let classCode = 1 // first
    public static let validFromDay = 0
    public static let validFromTime = 1000
    public static let validUntilDay = 1
    public static let validUntilTime = 1000
    public static let numberOfDaysOfTravel = 10
    public static let price = 10000
    public static let infoText = "pass info"

    // TrainValidity
    public static let trainValidityFromDay = 0
    public static let trainValidityFromTime = 1000
    public static let trainValidityUntilDay = 1
    public static let trainValidityUntilTime = 1000
    public static let includedCarriers = [1234, 5678]
    public static let boardingOrArrival = 0 // boarding

    // Activated days
    public static let activatedDays = [200, 201]

    // Countries
    public static let countries = [10, 20]

    // VatDetail
    public static let vatCountry = 80
    public static let vatPercentage = 70
    public static let vatAmount = 10
    public static let vatId = "IUDGTE"

    // Token
    public static let tokenProviderIA5 = "XYZ"
    public static let tokenData = Data([0x82, 0xDA])
}
