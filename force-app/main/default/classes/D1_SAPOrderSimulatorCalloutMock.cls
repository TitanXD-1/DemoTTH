/**
 * @name : D1_SAPOrderSimulatorCalloutMock
 * @description : callout Mock for  D1_SAPOrderSimulator
 * @author : Dipanjan Das
 * @history :
 * VERSION              AUTHOR                          DATE                DETAIL
 * 1.0                  Dipanjan Das                    01/10/2021          NCP-1834
 * 2.0                  Kapil Baliyan                   01/12/2022          NCP-7580
 */
@SuppressWarnings('PMD.LocalVariableNamingConventions')
 @isTest
 global class D1_SAPOrderSimulatorCalloutMock implements WebserviceMock {
	 global void doInvoke(
		 Object stub,
		 Object request,
		 Map<String, Object> response,
		 String endpoint,
		 String soapAction,
		 String requestName,
		 String responseNS,
		 String responseName,
		 String responseType){
			 // start - specify the response you want to send
			 D1_OrderSimulationController.DT_SalesOrderSimulate_Header_Response header_Response_X = new D1_OrderSimulationController.DT_SalesOrderSimulate_Header_Response();
			 header_Response_X.PURCH_NO_C = '123456789';
			 header_Response_X.VALUE = '123456789';
			 header_Response_X.TAX = '123';
			 header_Response_X.CURRENCY_x = '123';
			 header_Response_X.ORDER_DATE = Date.today();
			 header_Response_X.BELOW_MIN = false;
			 header_Response_X.ABOVE_MAX = false;
			 header_Response_X.MESSAGE_VALUE = 'Test';
			 header_Response_X.OUTSIDE_ATP = false;
			 header_Response_X.ATP_DAYS = 5;
		 
			 List<D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1> item_response_x_List = new List<D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1>();
			 D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1 item_response_x =  new D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1();
			 item_response_x.ITM_NUMBER = 'test string';
			 item_response_x.MATERIAL  = 'test string';
			 item_response_x.MAT_ENTRD = 'test string';
			 item_response_x.TARGET_QTY = '1';
			 item_response_x.KBMENG = '1';
			 item_response_x.SALES_UNIT = 'CAS';
			 item_response_x.PRICE = '0.0';
			 item_response_x.TAX = '0.0';
			 item_response_x.CURRENCY_x = 'GBP';
			 item_response_x.DEPOSIT = 'test string';
			 item_response_x.PRICE_ERROR = false;
			 item_response_x.QUANTITY_ERROR = false;
			 item_response_x.BELOW_MIN = false;
			 item_response_x.MESSAGE_VALUE  = 'test string';
			 item_response_x.YPRI_VALUE = 15.2;
			 item_response_x.ICM3_VALUE  = 15.2;
			 item_response_x.IPI3_VALUE = 15.2;
			 item_response_x.ZBPI_VALUE = 15.2;
			 item_response_x.ZBCF_VALUE = 15.2;
			 item_response_x.ICS3_VALUE = 15.2;
			 item_response_x.ICMI_VALUE = 15.2;
			 item_response_x.ZBNF_VALUE = 15.2;
			 item_response_x.YZ51_VALUE = 15.2;
			 item_response_x.ZEFI_VALUE = 15.2;
			 item_response_x.YMA7_VALUE = 15.2;
			 item_response_x.YMA8_VALUE = 15.2;
			 item_response_x.ICM3_RATE = 15.2;
			 item_response_x.IPI3_RATE = 15.2;
			 item_response_x.ZBPI_RATE = 15.2;
			 item_response_x.ZBCF_RATE = 15.2;
			 item_response_x.ICS3_RATE = 15.2;
			 item_response_x.YZ51_RATE = 15.2;
			 item_response_x.ZEFI_RATE = 15.2;
			 item_response_x.YMA7_RATE = 15.2;
			 item_response_x.YMA8_RATE = 15.2;
			 item_response_x.YMAX_RATE = 15.2;
			 item_response_x.YMIN_RATE = 15.2;
			 item_response_x.YMIW_RATE = 15.2;
			 item_response_x.YMIV_RATE = 15.2;
			 item_response_x.LISTPRICE_UNIT = '0.0';
			 item_response_x.UNITARY_REBATE = '0.0';
			 item_response_x.COMMERCIAL_DISCOUNT = '0%';
			 item_response_x.LOGISTIC_DISCOUNT = '0.0';
			 item_response_x.OTHER_DISCOUNT = '0%';
			 item_response_x.DISCOUNT_CURRMARK = '0.0';
			 item_response_x.SPECIAL_TAXDUTY = '0.0';
			 item_response_x.NETVALUE_UNIT = '0.0';
			 item_response_x.VAT = '0.0';
			 item_response_x_List.add(item_response_x);
		 
			 List<D1_OrderSimulationController.DT_SalesOrderSimulate_Message_Response> msg_response_x_List = new List<D1_OrderSimulationController.DT_SalesOrderSimulate_Message_Response>();
			 D1_OrderSimulationController.DT_SalesOrderSimulate_Message_Response  msg_response_x = new D1_OrderSimulationController.DT_SalesOrderSimulate_Message_Response();
			 msg_response_x.TYPE_x = 'Test';
			 msg_response_x.MESSAGE = 'Test';
			 msg_response_x.ID = '12345';
			 msg_response_x.NUMBER_x = '123425';  
			 msg_response_x_List.add(msg_response_x);
			 D1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1 response_x =  new D1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1();
			 
			 response_x.VBELN = 'Test';
			 response_x.STATUS = 'Success';
			 response_x.HEADER  = header_Response_X ;
			 response_x.ITEMS  = item_response_x_List ;
			 response_x.MESSAGES  = msg_response_x_List;
			 response.put('response_x', response_x);
	 }
 }