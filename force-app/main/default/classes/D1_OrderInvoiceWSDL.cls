/**
 * @name : D1_OrderInvoiceWSDL
 * @description : WSDL Class for Order Invoice Interface
 * @interface : I00254
 * @history                                                                                                                        
 * VERSION     AUTHOR               DATE              DETAIL
 * 1.0         Manikant Prasad      08/01/2021         Initial Development(NCP-1369)
 * 2.0         Mukesh Kanth         20/06/2024         Schema Invoice processing - Brazil Order Detail page (152950)
 **/
@SuppressWarnings('PMD.FieldNamingConventions,PMD.LocalVariableNamingConventions,PMD.MethodNamingConventions,PMD.FormalParameterNamingConventions')
public class D1_OrderInvoiceWSDL {
    public class DT_Invoice_OrdNo_Response_D1 {
        public String INVOICE_ID;
        public String PDF_DATA;
        public Boolean SUCCESS;
        public String STATUS;
        private String[] INVOICE_ID_type_info = new String[]{'INVOICE_ID','urn:diageo.com:common',null,'1','1','false'};
        private String[] PDF_DATA_type_info = new String[]{'PDF_DATA','urn:diageo.com:common',null,'1','1','false'};
        private String[] SUCCESS_type_info = new String[]{'SUCCESS','urn:diageo.com:common',null,'1','1','false'};
        private String[] STATUS_type_info = new String[]{'STATUS','urn:diageo.com:common',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:diageo.com:common','false','false'};
        private String[] field_order_type_info = new String[]{'INVOICE_ID','PDF_DATA','SUCCESS','STATUS'};
    }
    public class DT_Invoice_OrdNo_Request_D1 {
        public String ORDER_NUM;
        public String SHIP_TO;
        public String DOC_ID;
		public String DEL_NUM;
        public String SALES_ORG;        
        private String[] ORDER_NUM_type_info = new String[]{'ORDER_NUM','urn:diageo.com:common',null,'1','1','false'};
        private String[] SHIP_TO_type_info = new String[]{'SHIP_TO','urn:diageo.com:common',null,'1','1','false'};
        private String[] DOC_ID_type_info = new String[]{'DOC_ID','urn:diageo.com:common',null,'1','1','false'};
        private String[] DEL_NUM_type_info = new String[]{'DEL_NUM','urn:diageo.com:common',null,'1','1','false'};
        private String[] SALES_ORG_type_info = new String[]{'SALES_ORG','urn:diageo.com:common',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:diageo.com:common','false','false'};
        private String[] field_order_type_info = new String[]{'ORDER_NUM','SHIP_TO','DOC_ID','DEL_NUM','SALES_ORG'};
    }
    
    public class HTTPS_Port {
        //public String endpoint_x = 'https://sappoast01.guww.net:52601/XISOAPAdapter/MessageServlet?senderParty=&senderService=BC_SFDC&receiverParty=&receiverService=&interface=SI_Invoice_OrdNo_Sync_Out_D1&interfaceNamespace=urn%3Adiageo.com%3Acommon';
        public string epurl = D1_SFToSAPConnectionUtility.getInterfaceEndPoint('Order_Invoice');
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        private String[] ns_map_type_info = new String[]{'urn:diageo.com:common', 'D1_OrderInvoiceWSDL'};
        public D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Response_D1 SI_Invoice_OrdNo_Sync_Out_D1(String ORDER_NUM,String SHIP_TO,String DOC_ID,String DEL_NUM,String SALES_ORG) {
            D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Request_D1 request_x = new D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Request_D1();
            request_x.ORDER_NUM = ORDER_NUM;
            request_x.SHIP_TO = SHIP_TO;
            request_x.DOC_ID = DOC_ID;
            request_x.DEL_NUM = DEL_NUM;
            request_x.SALES_ORG = SALES_ORG;
            D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Response_D1 response_x;
            Map<String, D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Response_D1> response_map_x = new Map<String, D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Response_D1>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{
              'callout:D1SAP_login_Details/' + epurl + '',
              'http://sap.com/xi/WebService/soap1.1',
              'urn:diageo.com:common',
              'MT_Invoice_OrdNo_Request_D1',
              'urn:diageo.com:common',
              'MT_Invoice_OrdNo_Response_D1',
              'D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Response_D1'}
            );
            response_x = response_map_x.get('response_x');
            return response_x;
        }
    }
}