/**
* @name : D1_OrderAcknowledgeWSDL
* @description : WSDL Class for OrderAcknowledge Interface
* @interface : I00424
* @history                                                                                                                   
* VERSION     AUTHOR            DATE              DETAIL
* 1.0         Kapil Baliyan     08/01/2021         Initial Development(NCP-1370)
**/
@SuppressWarnings('PMD.FieldNamingConventions,PMD.LocalVariableNamingConventions,PMD.MethodNamingConventions,PMD.FormalParameterNamingConventions')
public class D1_OrderAcknowledgeWSDL {
    public class DT_OrderAck_Request {
        public String CUSTOMER;
        public String SAP_SALES_AREA;
        public String DOCID;
        private String[] CUSTOMER_type_info = new String[]{'CUSTOMER','urn:diageo.com:common',null,'1','1','false'};
        private String[] SAP_SALES_AREA_type_info = new String[]{'SAP_SALES_AREA','urn:diageo.com:common',null,'1','1','false'};
        private String[] DOCID_type_info = new String[]{'DOCID','urn:diageo.com:common',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:diageo.com:common','false','false'};
        private String[] field_order_type_info = new String[]{'CUSTOMER','SAP_SALES_AREA','DOCID'};
    }
    public class DT_OrderAck_Response {
        public String DOCID;
        public String PDF_DATA;
        public Boolean SUCCESS;
        private String[] DOCID_type_info = new String[]{'DOCID','urn:diageo.com:common',null,'1','1','false'};
        private String[] PDF_DATA_type_info = new String[]{'PDF_DATA','urn:diageo.com:common',null,'1','1','false'};
        private String[] SUCCESS_type_info = new String[]{'SUCCESS','urn:diageo.com:common',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:diageo.com:common','false','false'};
        private String[] field_order_type_info = new String[]{'DOCID','PDF_DATA','SUCCESS'};
    }
    public class HTTPS_Port {
        public string epurl = D1_SFToSAPConnectionUtility.getInterfaceEndPoint('Order_Acknowledge_Endpoint');
        public String endpoint_x = 'https://sappoast01.guww.net:52601/XISOAPAdapter/MessageServlet?senderParty=&senderService=BC_SFDC&receiverParty=&receiverService=&interface=SI_OrderAck_Sync_Out_D1&interfaceNamespace=urn%3Adiageo.com%3Acommon';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        private String[] ns_map_type_info = new String[]{'urn:diageo.com:common', 'D1_OrderAcknowledgeWSDL'};
        public D1_OrderAcknowledgeWSDL.DT_OrderAck_Response SI_OrderAck_Sync_Out_D1(String CUSTOMER,String SAP_SALES_AREA,String DOCID) {
            D1_OrderAcknowledgeWSDL.DT_OrderAck_Request request_x = new D1_OrderAcknowledgeWSDL.DT_OrderAck_Request();
            request_x.CUSTOMER = CUSTOMER;
            request_x.SAP_SALES_AREA = SAP_SALES_AREA;
            request_x.DOCID = DOCID;
            D1_OrderAcknowledgeWSDL.DT_OrderAck_Response response_x;
            Map<String, D1_OrderAcknowledgeWSDL.DT_OrderAck_Response> response_map_x = new Map<String, D1_OrderAcknowledgeWSDL.DT_OrderAck_Response>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{
               //endpoint_x,
              'callout:D1SAP_login_Details/' + epurl + '',
              'http://sap.com/xi/WebService/soap1.1',
              'urn:diageo.com:common',
              'MT_OrderAck_Request',
              'urn:diageo.com:common',
              'MT_OrderAck_Response',
              'D1_OrderAcknowledgeWSDL.DT_OrderAck_Response'}
            );
            response_x = response_map_x.get('response_x');
            return response_x;
        }
    }
}