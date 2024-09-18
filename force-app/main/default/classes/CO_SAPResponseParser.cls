/*
@Name: CO_SAPResponseParser

@Purpose: This class is used to parse the Customer Request response from SAP

@History                                                            
                                                           
VERSION    AUTHOR            DATE              DETAIL
1.0        Venkatesh Varma      10-26-2022        Initial Development

*/

public class CO_SAPResponseParser {
    
    public string errorType {get;set;}
    public string errorMessage {get;set;}
    public string errorCode {get;set;}
    public string errorDescription {get;set;}
    
    public CO_SAPResponseParser(JSONParser parser){
        processParser(parser);
    }

	private void processParser(JSONParser parser){
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					switch on text {
						when 'errorType' {
							this.errorType = parser.getText();
						}when 'errorMessage' {
							this.errorMessage = parser.getText();
						}when 'errorCode' {
							this.errorCode = parser.getText();
						}when 'errorDescription' {
							this.errorDescription = parser.getText();
						}when else {
							System.debug(LoggingLevel.WARN, 'CO_SendToSAP consuming unrecognized property: '+text);
						}
					}
				}
			}
		}
	}

    
    public static CO_SAPResponseParser parser(String json){
        System.JSONParser parser = System.JSON.createParser(json);
		return new CO_SAPResponseParser(parser);        
    }
}