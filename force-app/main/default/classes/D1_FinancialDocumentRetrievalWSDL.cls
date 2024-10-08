//Generated by wsdl2apex
@SuppressWarnings('PMD.FieldNamingConventions,PMD.LocalVariableNamingConventions,PMD.MethodNamingConventions,PMD.FormalParameterNamingConventions,PMD.ExcessiveParameterList')
public class D1_FinancialDocumentRetrievalWSDL {

    public class DT_FinancialDocumentRetrieval_Request {
        public String CUSTOMER;
        public String DOCTY;
        public String DOCID;
        public String DOCDATE;
        public String SALES_ORG;
        private String[] CUSTOMER_type_info = new String[]{'CUSTOMER','urn:diageo.com:common',null,'1','1','false'};
        private String[] DOCTY_type_info = new String[]{'DOCTY','urn:diageo.com:common',null,'1','1','false'};
        private String[] DOCID_type_info = new String[]{'DOCID','urn:diageo.com:common',null,'1','1','false'};
        private String[] DOCDATE_type_info = new String[]{'DOCDATE','urn:diageo.com:common',null,'1','1','false'};
        private String[] SALES_ORG_type_info = new String[]{'SALES_ORG','urn:diageo.com:common',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:diageo.com:common','false','false'};
        private String[] field_order_type_info = new String[]{'CUSTOMER','DOCTY','DOCID','DOCDATE','SALES_ORG'};
    }
    public class DT_FinancialDocumentRetrieval_Response_D1 {
        public String DOCID;
        public String PDF_DATA;
        public Boolean SUCCESS;
        public String STATUS;
        private String[] DOCID_type_info = new String[]{'DOCID','urn:diageo.com:common',null,'1','1','false'};
        private String[] PDF_DATA_type_info = new String[]{'PDF_DATA','urn:diageo.com:common',null,'1','1','false'};
        private String[] SUCCESS_type_info = new String[]{'SUCCESS','urn:diageo.com:common',null,'1','1','false'};
        private String[] STATUS_type_info = new String[]{'STATUS','urn:diageo.com:common',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:diageo.com:common','false','false'};
        private String[] field_order_type_info = new String[]{'DOCID','PDF_DATA','SUCCESS','STATUS'};
    }
    public class HTTPS_Port {
        //public String endpoint_x = 'https://sappoast01.guww.net:52601/XISOAPAdapter/MessageServlet?senderParty=&senderService=BC_SFDC&receiverParty=&receiverService=&interface=SI_FinancialDocumentRetrieval_Sync_Out_D1&interfaceNamespace=urn%3Adiageo.com%3Acommon';
         public string epurl = D1_SFToSAPConnectionUtility.getInterfaceEndPoint('Financial_Doc');
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        private String[] ns_map_type_info = new String[]{'urn:diageo.com:common', 'D1_FinancialDocumentRetrievalWSDL'};
        public D1_FinancialDocumentRetrievalWSDL.DT_FinancialDocumentRetrieval_Response_D1 SI_FinancialDocumentRetrieval_Sync_Out_D1(String CUSTOMER,String DOCTY,String DOCID,String DOCDATE,String SALES_ORG) {
            D1_FinancialDocumentRetrievalWSDL.DT_FinancialDocumentRetrieval_Request request_x = new D1_FinancialDocumentRetrievalWSDL.DT_FinancialDocumentRetrieval_Request();
            request_x.CUSTOMER = CUSTOMER;
            request_x.DOCTY = DOCTY;
            request_x.DOCID = DOCID;
            request_x.DOCDATE = DOCDATE;
            request_x.SALES_ORG = SALES_ORG;
            D1_FinancialDocumentRetrievalWSDL.DT_FinancialDocumentRetrieval_Response_D1 response_x;
            Map<String, D1_FinancialDocumentRetrievalWSDL.DT_FinancialDocumentRetrieval_Response_D1> response_map_x = new Map<String, D1_FinancialDocumentRetrievalWSDL.DT_FinancialDocumentRetrieval_Response_D1>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{'callout:D1SAP_login_Details/' + epurl + '',
              'http://sap.com/xi/WebService/soap1.1',
              'urn:diageo.com:common',
              'MT_FinancialDocumentRetrieval_Request',
              'urn:diageo.com:common',
              'MT_FinancialDocumentRetrieval_Response_D1',
              'D1_FinancialDocumentRetrievalWSDL.DT_FinancialDocumentRetrieval_Response_D1'}
            );
            response_x = response_map_x.get('response_x');
            return response_x;
        }
    }
}