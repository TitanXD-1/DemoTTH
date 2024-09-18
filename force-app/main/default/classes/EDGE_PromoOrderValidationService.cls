/**

* @Description: EDGE_PromoOrderValidationService

* @Purpose: Service to detect available and unavailable promotions 

* @VERSION     AUTHOR         		 DATE            DETAIL

* 	1.0		  Swaraj Samanta 	 15/07/2022       ES20-12823

*/ 

/*Sample 
 /services/apexrest/PromoOrderValidationService
{
"User_Id" : "0053W000000aQzlQAE",
"Outlet_Id" : "0017a00001xzT6qAAE",
"Promotion_List" : ["a5B7a000000XSTAEA4", "a5B7a000000XSTFEA4","a5B7a000000XSTKEA4", "a5B7a000000XSTPEA4"]
}
*/

@RestResource(urlMapping='/PromoOrderValidationService/*')
global with sharing class EDGE_PromoOrderValidationService { 
    
    @HttpPost    
    global static void validatePromoOrders(){
        
        RestRequest request = RestContext.request;
        EDGE_PromoOutletOutputWrapper promoOutletOutput = new EDGE_PromoOutletOutputWrapper();
        
        RestResponse resp = RestContext.response;
        resp.addHeader('Accept', 'application/json');
        resp.addHeader('Content-Type', 'application/json');
        
        if (request.requestBody != null){
            EDGE_PromoOutletInputWrapper inputData = (EDGE_PromoOutletInputWrapper) JSON.deserialize(request.requestBody.toString(),EDGE_PromoOutletInputWrapper.class);
            promoOutletOutput = EDGE_PromoOrderValidationController.getPromotionDetails(inputData);
            
        }
        //returing promotion list body within rest response
        resp.responseBody = Blob.valueOf(JSON.serialize(promoOutletOutput));
    }
}