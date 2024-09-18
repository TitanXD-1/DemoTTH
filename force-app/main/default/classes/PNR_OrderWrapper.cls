/**********************************************************************
  Name: PNR_OrderWrapper
=======================================================================
Req : US- This wrapper class is used to parse Order Response
=======================================================================
    History                                                            
    -------                                                            
    VERSION   AUTHOR            DATE              DETAIL
     1.0      Saurav Paul     30/07/2019      Initial Development
***********************************************************************/
public class PNR_OrderWrapper {

	public class Order {
		public String salesDocumentNumber {get;set;} 
		public String salesDocumentType {get;set;} 
		public String salesOrganization {get;set;} 
		public String distributionChannel {get;set;} 
		public String division {get;set;} 
		public String purchaseOrderNumber {get;set;} 
		public String soldToParty {get;set;} 
		public String payer {get;set;} 
		public String shipToParty {get;set;} 
		public String requestedDeliveryDate {get;set;} 
		public Double netValueInDocumentCurrency {get;set;} 
		public String sdDocumentCurrency {get;set;} 
		public String orderReason {get;set;} 
		public String nameOfPersonCreatedObject {get;set;} 
		public String deliveryBlock {get;set;} 
		public String billingBlockInSDDocument {get;set;} 
		public String overallStatusOfCreditChecks {get;set;} 
		public String overallBlockedStatus {get;set;} 
		public String plant {get;set;} 
		public String dateForPricingAndExchangeRate {get;set;} 
		public String incotermsPart1 {get;set;} 
		public String incotermsPart2 {get;set;} 
		public String deliveryDocument {get;set;} 
		public String plannedGoodsMovementDate {get;set;} 
		public String billingDocument {get;set;} 
		public Boolean deletionIndicatorFlag {get;set;} 

		public Order(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'salesDocumentNumber') {
							salesDocumentNumber = parser.getText();
						} else if (text == 'salesDocumentType') {
							salesDocumentType = parser.getText();
						} else if (text == 'salesOrganization') {
							salesOrganization = parser.getText();
						} else if (text == 'distributionChannel') {
							distributionChannel = parser.getText();
						} else if (text == 'division') {
							division = parser.getText();
						} else if (text == 'purchaseOrderNumber') {
							purchaseOrderNumber = parser.getText();
						} else if (text == 'soldToParty') {
							soldToParty = parser.getText();
						} else if (text == 'payer') {
							payer = parser.getText();
						} else if (text == 'shipToParty') {
							shipToParty = parser.getText();
						} else if (text == 'requestedDeliveryDate') {
							requestedDeliveryDate = parser.getText();
						} else if (text == 'netValueInDocumentCurrency') {
							netValueInDocumentCurrency = parser.getDoubleValue();
						} else if (text == 'sdDocumentCurrency') {
							sdDocumentCurrency = parser.getText();
						} else if (text == 'orderReason') {
							orderReason = parser.getText();
						} else if (text == 'nameOfPersonCreatedObject') {
							nameOfPersonCreatedObject = parser.getText();
						} else if (text == 'deliveryBlock') {
							deliveryBlock = parser.getText();
						} else if (text == 'billingBlockInSDDocument') {
							billingBlockInSDDocument = parser.getText();
						} else if (text == 'overallStatusOfCreditChecks') {
							overallStatusOfCreditChecks = parser.getText();
						} else if (text == 'overallBlockedStatus') {
							overallBlockedStatus = parser.getText();
						} else if (text == 'plant') {
							plant = parser.getText();
						} else if (text == 'dateForPricingAndExchangeRate') {
							dateForPricingAndExchangeRate = parser.getText();
						} else if (text == 'incotermsPart1') {
							incotermsPart1 = parser.getText();
						} else if (text == 'incotermsPart2') {
							incotermsPart2 = parser.getText();
						} else if (text == 'deliveryDocument') {
							deliveryDocument = parser.getText();
						} else if (text == 'plannedGoodsMovementDate') {
							plannedGoodsMovementDate = parser.getText();
						} else if (text == 'billingDocument') {
							billingDocument = parser.getText();
						} else if (text == 'deletionIndicatorFlag') {
							deletionIndicatorFlag = parser.getBooleanValue();
						} else {
							System.debug(LoggingLevel.WARN, 'Order consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class Orders {
		public Order order {get;set;} 

		public Orders(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'order') {
							Order = new Order(parser);
						} else {
							System.debug(LoggingLevel.WARN, 'Orders consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public String status {get;set;} 
	public Integer recordCount {get;set;} 
	public String statusDescription {get;set;} 
	public Orders orders {get;set;} 

	public PNR_OrderWrapper(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'status') {
						status = parser.getText();
					} else if (text == 'recordCount') {
						recordCount = parser.getIntegerValue();
					} else if (text == 'statusDescription') {
						statusDescription = parser.getText();
					} else if (text == 'orders') {
						Orders = new Orders(parser);
					} else {
						System.debug(LoggingLevel.WARN, 'PNR_OrderWrapper consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
	
	
	public static PNR_OrderWrapper parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new PNR_OrderWrapper(parser);
	}
	
	public static void consumeObject(System.JSONParser parser) {
		Integer depth = 0;
		do {
			System.JSONToken curr = parser.getCurrentToken();
			if (curr == System.JSONToken.START_OBJECT || 
				curr == System.JSONToken.START_ARRAY) {
				depth++;
			} else if (curr == System.JSONToken.END_OBJECT ||
				curr == System.JSONToken.END_ARRAY) {
				depth--;
			}
		} while (depth > 0 && parser.nextToken() != null);
	}
}