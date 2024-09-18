/**
* @Name: EDGE_StockMovementOrderEmailHelper

* @Purpose: To Create Email Template for StockMovementOrder.

* @History                                                            
                                                           
* @VERSION   AUTHOR                    DATE              DETAIL
*  1.0       Uppalapati Anand          13/08/2021        ES20-10486
*/


public class EDGE_StockMovementOrderEmailHelper {
    
    public static string getStockMovementMailTemplate(List<Order__c> orderList,  Map<String,List<Order_Item__c>> orderToOrderItemMap){
        
        String htmlBody = '';
        String todayDate = date.today().format();
        system.debug('@@todayDate'+todayDate);
        
        htmlBody+= +Label.EDGE_Email_Body+' ' + todayDate;
        htmlBody+='<br> </br>';
        htmlBody+= '<table style="border:1px solid balck;">';  
        
        if(orderList!=null && orderList.size()>0){
            for(Order__c ordObj: orderList){
                htmlBody += '<tr>';
                htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_Stockmvment_Order_Number+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;">'+(ordObj.Name != null ? ordObj.Name : '')+'</td>';
                htmlBody += '</tr>';
                htmlBody += '<tr>';
                htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_Order_Date+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;">'+todayDate+'</td>';
                htmlBody += '</tr>';
                htmlBody += '<tr>';
                htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_Delivery_Location+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;">'+(ordObj.Delivery_Location__c != null ? ordObj.Delivery_Location__c : '')+'</td>';
                htmlBody += '</tr>';
                htmlBody += '<tr>';
                htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_Order_Type+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;">'+(ordObj.Order_Type__c != null ? ordObj.Order_Type__c : '')+'</td>';
                htmlBody += '</tr>';
                htmlBody += '<tr>';
                htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_SalesRep_Name+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;">'+(ordObj.Sales_Representative__c != null ? ordObj.Sales_Representative__r.Name : '')+'</td>';
                htmlBody += '</tr>';
                htmlBody += '<tr>';

                htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_SalesRep_Mobile+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;">'+(ordObj.Sales_Representative__c != null && ordObj.Sales_Representative__r.MobilePhone != null ? ordObj.Sales_Representative__r.MobilePhone: '')+'</td>';

                htmlBody += '</tr>';
                htmlBody += '<tr>';
                htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_SalesRep_Email+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;">'+(ordObj.Sales_Representative__c != null ? ordObj.Sales_Representative__r.Email : '')+'</td>';
                htmlBody += '</tr>';
                htmlBody += '<tr>';

                htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_Shed_Address+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;">'+((ordObj.Account__r.BillingStreet !=null ? ordObj.Account__r.BillingStreet:'')+' '+(ordObj.Account__r.BillingCity != null ? ordObj.Account__r.BillingCity:'') +' '+(ordObj.Account__r.BillingPostalCode != null ?ordObj.Account__r.BillingPostalCode:'') +' '+(ordObj.Account__r.BillingCountry != null ? ordObj.Account__r.BillingCountry:'') )+'</td>';

                htmlBody += '</tr>';
                htmlBody += '<tr>';
                htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_Product_Name+'</td>';
                htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_Product_Quantity+'</td>';
                htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_Reason+'</td>';
                htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_Unit_Of_Measure+'</td>';
                htmlBody += '</tr>';
                //Mail body for Order Items
                if(orderToOrderItemMap.size()>0 && orderToOrderItemMap.containsKey(ordObj.Id)){
                    List<Order_Item__c> orderItemList = orderToOrderItemMap.get(ordObj.Id);
                    if(orderItemList != null && orderItemList.size() > 0){
                        Integer ordItemQuantity = orderItemList.size();
                        for(integer i=0;i<ordItemQuantity;i++){
                            htmlBody += '<tr>';
                            htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' +((orderItemList[i].Product__r.Name)!=null? orderItemList[i].Product__r.Name:'') + '</td>';
                            htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' +  orderItemList[i].Quantity__c + '</td>';
                            htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' + ((orderItemList[i].Reason__c)!=null? orderItemList[i].Reason__c:'') + '</td>';
                            htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' + ((orderItemList[i].Selected_UoM__c)!=null? orderItemList[i].Selected_UoM__c:'') + '</td>';
                            htmlBody += '</tr>';
                        }
                    }
                    
                }
            }
        }
        
        htmlBody += '</table>';
        return htmlBody;
   }

}