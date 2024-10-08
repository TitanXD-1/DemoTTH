//Generated by wsdl2apex

public class RB_SapReturnBeerWebCallout {
    public class DT_ReturnBeerTags_Request_D1 {
        public RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_CreateTag_D1[] tag;
        private String[] tag_type_info = new String[]{'tag','urn:diageo.com:common',null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:diageo.com:common','false','false'};
        private String[] field_order_type_info = new String[]{'tag'};
    }
    public class DT_ReturnBeerTags_CreateTag_D1 {
        public String sfdcid;
        public String country;
        public String tagnum;
        public String kegnum;
        public String matnr;
        public String ship_to;
        public String sold_to;
        public String reason_cat;
        public String reason;
        public String out_vol;
        public DateTime create_date;
        public Boolean sampled;
        public Boolean broached;
        public String qrep;
        public String disrep;
        public String salesrep;
        public String srvcrep;
        public String qualrep_reg;
        public String salerep_reg;
        public String disprep_reg;
        public String srvcrep_reg;
        public String lead_srvcrep_terr;
        public String rqm_terr;
        private String[] sfdcid_type_info = new String[]{'sfdcid','urn:diageo.com:common',null,'1','1','false'};
        private String[] country_type_info = new String[]{'country','urn:diageo.com:common',null,'1','1','false'};
        private String[] tagnum_type_info = new String[]{'tagnum','urn:diageo.com:common',null,'1','1','false'};
        private String[] kegnum_type_info = new String[]{'kegnum','urn:diageo.com:common',null,'1','1','false'};
        private String[] matnr_type_info = new String[]{'matnr','urn:diageo.com:common',null,'1','1','false'};
        private String[] ship_to_type_info = new String[]{'ship_to','urn:diageo.com:common',null,'1','1','false'};
        private String[] sold_to_type_info = new String[]{'sold_to','urn:diageo.com:common',null,'1','1','false'};
        private String[] reason_cat_type_info = new String[]{'reason_cat','urn:diageo.com:common',null,'1','1','false'};
        private String[] reason_type_info = new String[]{'reason','urn:diageo.com:common',null,'1','1','false'};
        private String[] out_vol_type_info = new String[]{'out_vol','urn:diageo.com:common',null,'1','1','false'};
        private String[] create_date_type_info = new String[]{'create_date','urn:diageo.com:common',null,'1','1','false'};
        private String[] sampled_type_info = new String[]{'sampled','urn:diageo.com:common',null,'1','1','false'};
        private String[] broached_type_info = new String[]{'broached','urn:diageo.com:common',null,'1','1','false'};
        private String[] qrep_type_info = new String[]{'qrep','urn:diageo.com:common',null,'1','1','false'};
        private String[] disrep_type_info = new String[]{'disrep','urn:diageo.com:common',null,'1','1','false'};
        private String[] salesrep_type_info = new String[]{'salesrep','urn:diageo.com:common',null,'1','1','false'};
        private String[] srvcrep_type_info = new String[]{'srvcrep','urn:diageo.com:common',null,'1','1','false'};
        private String[] qualrep_reg_type_info = new String[]{'qualrep_reg','urn:diageo.com:common',null,'1','1','false'};
        private String[] salerep_reg_type_info = new String[]{'salerep_reg','urn:diageo.com:common',null,'1','1','false'};
        private String[] disprep_reg_type_info = new String[]{'disprep_reg','urn:diageo.com:common',null,'1','1','false'};
        private String[] srvcrep_reg_type_info = new String[]{'srvcrep_reg','urn:diageo.com:common',null,'1','1','false'};
        private String[] lead_srvcrep_terr_type_info = new String[]{'lead_srvcrep_terr','urn:diageo.com:common',null,'1','1','false'};
        private String[] rqm_terr_type_info = new String[]{'rqm_terr','urn:diageo.com:common',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:diageo.com:common','false','false'};
        private String[] field_order_type_info = new String[]{'sfdcid','country','tagnum','kegnum','matnr','ship_to','sold_to','reason_cat','reason','out_vol','create_date','sampled','broached','qrep','disrep','salesrep','srvcrep','qualrep_reg','salerep_reg','disprep_reg','srvcrep_reg','lead_srvcrep_terr','rqm_terr'};
    }
    public class DT_ReturnBeerTags_Response {
        public Boolean success;
        private String[] success_type_info = new String[]{'success','urn:diageo.com:common',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:diageo.com:common','false','false'};
        private String[] field_order_type_info = new String[]{'success'};
    }
    public class HTTPS_Port {
        //public String endpoint_x = 'https://pocloud-qa.diageo.com/XISOAPAdapter/MessageServlet?senderParty=&senderService=BC_SFDC&receiverParty=&receiverService=&interface=SI_ReturnBeerTags_Sync_Out_D1&interfaceNamespace=urn%3Adiageo.com%3Acommon';
        public String endpoint_x;
        public string epurl = D1_SFToSAPConnectionUtility.getInterfaceEndPoint('EDGE_RBTag_SAP');//ES20-13880
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        private String[] ns_map_type_info = new String[]{'urn:diageo.com:common', 'RB_SapReturnBeerWebCallout'};
        public Boolean SI_ReturnBeerTags_Sync_Out_D1(RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_CreateTag_D1[] tag) {
            RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_Request_D1 request_x = new RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_Request_D1();
            request_x.tag = tag;
            RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_Response response_x;
            Map<String, RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_Response> response_map_x = new Map<String, RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_Response>();
            response_map_x.put('response_x', response_x);
            
            //ES20-13880 added named credential
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{'callout:D1SAP_login_Details/' + epurl + '',
              'http://sap.com/xi/WebService/soap1.1',
              'urn:diageo.com:common',
              'MT_ReturnBeerTags_Request_D1',
              'urn:diageo.com:common',
              'MT_ReturnBeerTags_Response',
              'RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_Response'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.success;
        }
    }
}