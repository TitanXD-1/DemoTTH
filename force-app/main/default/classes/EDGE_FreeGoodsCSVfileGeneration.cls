public with sharing class EDGE_FreeGoodsCSVfileGeneration {
    public  void generateCSV(Order__c order){
        String freeGoodsCSV = 'Free Goods Order,,,,,,,,\n'+
            ',,,,,,,,\n'+
            ',,,,,,,,\n'+
            ',,,,,,,,\n'+
            ',,,,,,,,\n'+
            ',,,,,,,,\n'+
            ',SECTION 1  - ORDER DETAILS ,,,,,,,\n'+
            ',,,,Dist Channel,10,Division,10,\n'+
            ',Sales Org ,M ,DE01,,,,,\n'+
            ',,,,,,,,\n'+
            ',,,,,,,,\n'+
            ',,,,,,,,\n'+
            ',,,,,,,,\n'+
            ',Sold to ,M,100760,,,,,\n'+
            ',Ship to ,M,27008816,,,,,\n'+
            ',Name,M,ffn,,,,,\n'+
            ',Street Address 1 ,M,ff,,,,,\n'+
            ',,,,,,,,\n'+
            ',City,M,ff,,,,,\n'+
            ',Postcode,M,ff,,,,,\n'+
            ',Country ,M,DE,,,,,\n'+
            ',,,,,,,,\n'+
            ',,,,,,,,\n'+
            ',PO Reference ,M,fgg,,,,,\n'+
            ',,,,,,,,\n'+
            ',,,,,,,,\n'+
            ',Reason Code SAP ,D,Y28,,,,,\n'+
            ',,,,,,,,\n'+
            ',,,,,,,,\n'+
            ',Required Delivery date ,M,12.01.2022,,,,,\n'+
            ',,,,,,,,\n'+
            ',Shipping Instruction,M,Please esnure that bottles are safely delivered,,,,,\n'+
            ',,,,,,,,\n'+
            ',,,,,,,,\n'+
            ',,,,,,,,\n'+
            ',,,,,,,,\n'+
            ',,,,,,,,\n'+
            ',SECTION 2  - PRODUCT DETAILS ,,,,,,,\n'+
            ',Description,Material #,QTY,UOM,,Internal Order ,,\n'+
            ',M,D,M,D,,M,,\n'+
            ',,,,,,,,\n'+
            '1,Baileys Original 1L 06x01 BOTAG1L,689388,1,BTL,,MNWXONTN04MA,,\n'+
            '2,Baileys Glas,570044,2,BTL,,MNWXONTN04PS,,\n'+
            '3,,,,,,,,\n'+
            '4,,,,,,,,\n'+
            '5,,,,,,,,\n'+
            '6,,,,,,,,\n'+
            '7,,,,,,,,\n'+
            '8,,,,,,,,\n'+
            '9,,,,,,,,\n'+
            '10,,,,,,,,\n'+
            '11,,,,,,,,\n'+
            '12,,,,,,,,\n'+
            '13,,,,,,,,\n'+
            '14,,,,,,,,\n'+
            '15,,,,,,,,\n'+
            '16,,,,,,,,\n'+
            '17,,,,,,,,\n'+
            '18,,,,,,,,\n'+
            '19,,,,,,,,\n'+
            '20,,,,,,,,\n'+
            ',,,,,,,,\n'+
            ',,,,,,,TOTAL ORDER COST ,500';
        //List<Order__c> orderList = new List<Order__c>();
        //Order__c order = [select id,name,Status__c,Delivery_instructions__c,CreatedById, CreatedDate,Order_Placed_Date__c,CreatedBy.Name,Sales_Representative__r.name, CreatedBy.email, Account__c,Account__r.Sales_Org__c, Account__r.name,Account__r.SAP_Ship_to__c, Account__r.SAP_Sold_to__c, Account__r.BillingCountry from Order__c where id =: orderss and Record_Type_Name__c = 'Free Goods' order by CreatedDate desc];
        freeGoodsCSV += freeGoodsCSV.replace('DE01,',String.isBlank(order.Account__r.Sales_Org__c)? ' ' : order.Account__r.Sales_Org__c);
        freeGoodsCSV += freeGoodsCSV.replace('100760,',order.Account__r.SAP_Sold_to__c);
        freeGoodsCSV += freeGoodsCSV.replace('27008816,',order.Account__r.SAP_Ship_to__c); 
        freeGoodsCSV += freeGoodsCSV.replace('ffn,',order.Account__r.Name);
        //String delIns = order.Delivery_instructions__c;
        freeGoodsCSV += freeGoodsCSV.replace('Please esnure that bottles are safely delivered,', String.isBlank(order.Delivery_instructions__c)? ' ' : order.Delivery_instructions__c); 
        //freeGoodsCSV += freeGoodsCSV.replace(freeGoodsCSV.contains('5,'));
    }
}