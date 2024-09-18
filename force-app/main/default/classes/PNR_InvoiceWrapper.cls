/**********************************************************************
  Name: PNR_InvoiceWrapper
=======================================================================
Req : US- This wrapper class is used to parse Invoice Response
=======================================================================
    History                                                            
    -------                                                            
    VERSION   AUTHOR            DATE              DETAIL
     1.0      Saurav Paul     30/07/2019      Initial Development
***********************************************************************/
public class PNR_InvoiceWrapper {

	public String status {get;set;} 
	public Integer recordCount {get;set;} 
	public String statusDescription {get;set;} 
	public Invoices invoices {get;set;} 

	public PNR_InvoiceWrapper(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'status') {
						status = parser.getText();
                        System.debug('$$$$$$$ status '+ status);
					} else if (text == 'recordCount') {
						recordCount = parser.getIntegerValue();
					} else if (text == 'statusDescription') {
						statusDescription = parser.getText();
					} else if (text == 'invoices') {
						invoices = new Invoices(parser);
					} else {
						System.debug(LoggingLevel.WARN, 'PNR_InvoiceWrapper consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
	
	public class InvoiceLines {
		public List<InvoiceLine> invoiceLine {get;set;} 

		public InvoiceLines(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'invoiceLine') {
							invoiceLine = arrayOfInvoiceLine(parser);
						} else {
							System.debug(LoggingLevel.WARN, 'InvoiceLines consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class Invoice {
		public String salesOrganization {get;set;} 
		public String distributionChannel {get;set;} 
		public String division {get;set;} 
		public String billingType {get;set;} 
		public String billingDocument {get;set;} 
		public String soldToParty {get;set;} 
		public String payer {get;set;} 
		public String billToParty {get;set;} 
		public String shipToParty {get;set;} 
		public Double grossValueInDocumentCurrency {get;set;} 
		public String sdDocumentCurrency {get;set;} 
		public String termsOfPaymentKey {get;set;} 
		public String salesOrderDocument {get;set;} 
		public String dueType {get;set;} 
		public String dueDate {get;set;} 
		public String poNumber {get;set;} 
        Public string ExternalIdentificationofDelivery {get;set;} //PION-2577
        public String Delivery {get;set;} //PION-2577
        public string ReferenceDocumentNumber {get;set;}//PION-2577
        public string BillingDate {get;set;}//PION-2577
		public InvoiceLines invoiceLines {get;set;} 

		public Invoice(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'salesOrganization') {
							salesOrganization = parser.getText();
						} else if (text == 'distributionChannel') {
							distributionChannel = parser.getText();
						} else if (text == 'division') {
							division = parser.getText();
						} else if (text == 'billingType') {
							billingType = parser.getText();
						} else if (text == 'billingDocument') {
							billingDocument = parser.getText();
						} else if (text == 'soldToParty') {
							soldToParty = parser.getText();
						} else if (text == 'payer') {
							payer = parser.getText();
						} else if (text == 'billToParty') {
							billToParty = parser.getText();
						} else if (text == 'shipToParty') {
							shipToParty = parser.getText();
						} else if (text == 'grossValueInDocumentCurrency') {
							grossValueInDocumentCurrency = parser.getDoubleValue();
						} else if (text == 'sdDocumentCurrency') {
							sdDocumentCurrency = parser.getText();
						} else if (text == 'termsOfPaymentKey') {
							termsOfPaymentKey = parser.getText();
						} else if (text == 'salesOrderDocument') {
							salesOrderDocument = parser.getText();
						} else if (text == 'dueType') {
							dueType = parser.getText();
						} else if (text == 'dueDate') {
							dueDate = parser.getText();
						} else if (text == 'poNumber') {
							poNumber = parser.getText();
                            // PION- 2577 Changes Start
                        } else if (text == 'ExternalIdentificationofDelivery') {
                            ExternalIdentificationofDelivery=parser.getText();
                         } else if (text == 'Delivery') {
                            Delivery=parser.getText();
                         } else if (text == 'ReferenceDocumentNumber') {
                             ReferenceDocumentNumber=parser.getText();
                          } else if (text == 'BillingDate') {
                            BillingDate=parser.getText();
                              // PION-2577 Changes end
					    } else if (text == 'invoiceLines') {
							invoiceLines = new InvoiceLines(parser);
						} else {
							System.debug(LoggingLevel.WARN, 'Invoice consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class InvoiceLine {
		public String lineItemNumber {get;set;} 
		public String materialNumber {get;set;} 
		public String materialDescription {get;set;} 
		public Integer actualInvoicedQuantity {get;set;} 
		public String salesUnit {get;set;} 
		public Double netPriceItem {get;set;} 
		public Double netPriceUnit {get;set;} 
		public String plant {get;set;} 
		public String batchNumber {get;set;} 

		public InvoiceLine(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'lineItemNumber') {
							lineItemNumber = parser.getText();
						} else if (text == 'materialNumber') {
							materialNumber = parser.getText();
						} else if (text == 'materialDescription') {
							materialDescription = parser.getText();
						} else if (text == 'actualInvoicedQuantity') {
							actualInvoicedQuantity = parser.getIntegerValue();
						} else if (text == 'salesUnit') {
							salesUnit = parser.getText();
						} else if (text == 'netPriceItem') {
							netPriceItem = parser.getDoubleValue();
						} else if (text == 'netPriceUnit') {
							netPriceUnit = parser.getDoubleValue();
						} else if (text == 'plant') {
							plant = parser.getText();
						} else if (text == 'batchNumber') {
							batchNumber = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'InvoiceLine consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class Invoices {
		public Invoice invoice {get;set;} 

		public Invoices(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'invoice') {
							invoice = new Invoice(parser);
						} else {
							System.debug(LoggingLevel.WARN, 'Invoices consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}

	public static PNR_InvoiceWrapper parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new PNR_InvoiceWrapper(parser);
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
	
    private static List<InvoiceLine> arrayOfInvoiceLine(System.JSONParser p) {
        List<InvoiceLine> res = new List<InvoiceLine>();
        if (p.getCurrentToken() == null) {
			p.nextToken();
		}
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new InvoiceLine(p));
        }
        return res;
    }
}