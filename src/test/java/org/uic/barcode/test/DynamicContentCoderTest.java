package org.uic.barcode.test;

import java.util.Date;

import org.junit.Before;
import org.junit.Test;
import org.uic.barcode.asn1.uper.UperEncoder;
import org.uic.barcode.dynamicContent.api.DynamicContentCoder;
import org.uic.barcode.dynamicContent.api.IUicDynamicContent;
import org.uic.barcode.dynamicContent.api.SimpleUicDynamicContent;
import org.uic.barcode.logger.LoggerFactory;
import org.uic.barcode.ticket.EncodingFormatException;
import org.uic.barcode.ticket.api.impl.SimpleExtension;
import org.uic.barcode.ticket.api.impl.SimpleGeoCoordinate;
import org.uic.barcode.ticket.api.spec.IExtension;
import org.uic.barcode.ticket.api.spec.IGeoCoordinate;

public class DynamicContentCoderTest {
	
	IUicDynamicContent content = null; 
	
	@Before public void initialize() {
		
		LoggerFactory.setActivateConsoleLog(true);
		
		content = new SimpleUicDynamicContent();		
		
		content.setAppId("appID");
	
		content.setChallengeString("challenge string");
		
		IExtension e = new SimpleExtension();
		e.setId("challenge_extension_id1");
		e.setBinarydata(UperEncoder.bytesFromHexString("82DA"));
		content.setExtension(e);
		
		IExtension e1 = new SimpleExtension();
		e1.setId("challenge_extension_id1");
		e1.setBinarydata(UperEncoder.bytesFromHexString("82DA"));
		content.addDynamicContentResponse(e1);
			
		content.setPhoneIdHash(UperEncoder.bytesFromHexString("83DA"));
		
		content.setPassIdHash(UperEncoder.bytesFromHexString("84DA"));
		
		IGeoCoordinate g = new SimpleGeoCoordinate();
		g.setLongitude( 12345L);
	    g.setLatitude(  56789L);
		content.setGeoCoordinate(g);
	
		Date date = new Date(1612438200000L);		
		content.setTimeStamp(date);	
		
	}

	@Test public void testDynamicContentEncoding() {
		
		
		byte[] encodedBytes = null;
		try {
			encodedBytes = DynamicContentCoder.encode(content, null);
		} catch (EncodingFormatException e) {
			assert(false);
		}
		
		String encoding = UperEncoder.hexStringFromBytes(encodedBytes);
		
		String expectedEncoding = "7C170F0E1262089437000230390300DDD504017A20C6D0C2D8D8CADCCECA40E6E8E4D2DCCE2F8F461D9B32EECF96FE5F1D32EEE7A77EEBFA72310282DA05E1A37EECA0507B409C30F3E60509B42F8F461D9B32EECF96FE5F1D32EEE7A77EEBFA72310282DA";

		assert(expectedEncoding.equals(encoding));
		
	}
	

	
	
}
