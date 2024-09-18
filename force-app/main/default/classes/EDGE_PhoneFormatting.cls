/*
*Name: EDGE_PhoneFormatting
*Purpose: ES20-496 - Phone number on Account & Contact to have international dial code of country as default value
*History                                                            

VERSION     AUTHOR              DATE                DETAIL
1.0         Preyanka Ghosh   02/09/2019          Initial Development
2.0			Nidhi Jaiswal	 14/09/2023          145713 :Update the error message for Phone & Mobile Field
02/08/2024
*/
public with sharing class EDGE_PhoneFormatting {
    
    private static String mobileNumber; 
    private static String phoneNumber;
    private static String  mobilePrefix;
    private static String  phonePrefix;

    /* @description :  - Concatenate International code with Phone number
    * @return : void
    * @param : List<String>, sObject
    */
    public static void concatenatePrefixPhone(List<String> lstFieldName, sObject record){
        mobileNumber = '';
        phoneNumber = '';
        mobilePrefix = '';
        phonePrefix = '';
        
        for(String fieldName : lstFieldName){
            if(fieldName.containsIgnoreCase('Mobile') && fieldName.containsIgnoreCase('Prefix') && record.get(fieldName) != null){
                mobilePrefix = (String)record.get(fieldName);
                mobileNumber = String.isBlank(mobileNumber) ? (String)record.get(fieldName) : (String)record.get(fieldName) + mobileNumber; 
            } else if(fieldName.containsIgnoreCase('Mobile') && !fieldName.containsIgnoreCase('Prefix') && record.get(fieldName) != null){
                mobileNumber = String.isBlank(mobileNumber) ? (String)record.get(fieldName) : mobileNumber +(String)record.get(fieldName);
            }
            
            if(fieldName.containsIgnoreCase('Phone') && fieldName.containsIgnoreCase('Prefix') && record.get(fieldName) != null){
                phonePrefix = (String)record.get(fieldName);
                phoneNumber = String.isBlank(phoneNumber) ? (String)record.get(fieldName) : (String)record.get(fieldName) + phoneNumber; 
            } else if(fieldName.containsIgnoreCase('Phone') && !fieldName.containsIgnoreCase('Prefix') && record.get(fieldName) != null){
                phoneNumber = String.isBlank(phoneNumber) ? (String)record.get(fieldName) : phoneNumber +(String)record.get(fieldName);
            }
        }
        
        System.debug(LoggingLevel.DEBUG,'mobileNumber:::'+mobileNumber);
        System.debug(LoggingLevel.DEBUG,'phoneNumber:::'+phoneNumber);
    }

    /* @description :  - Populate Phone number to sObject mobile/phone field
    * @return : void
    * @param : List<String>, sObject
    */
    public static void populatePhoneNumber(List<String> lstFieldToUpdate, sObject recordToUpdate){
        if(lstFieldToUpdate != null && recordToUpdate != null){            
            for(String fieldToUpdate : lstFieldToUpdate){
                if(fieldToUpdate.containsIgnoreCase('Mobile')){	
                    recordToUpdate.put(fieldToUpdate, mobileNumber);
                } else if(fieldToUpdate.containsIgnoreCase('Phone') && !fieldToUpdate.containsIgnoreCase('Mobile')){
                    recordToUpdate.put(fieldToUpdate, phoneNumber);
                }
            }
        }        
    }

    /* @description :  - Validate Phone number depending upon regex set on metadata
    * @return : void
    * @param : List<String>, sObject
    */
    public static void validatePhoneNumber(List<sObject> lstNewData, Set<String> setPhonePrefix, List<String> lstFieldName, List<String> lstFieldToUpdate){
        Map<String, List<Phone_Format__mdt>> mapPhoneFormat = new Map<String, List<Phone_Format__mdt>>();
        
        if(lstNewData != null && setPhonePrefix != null && lstFieldName != null && lstFieldToUpdate!=null){            
            //Get both landline and mobile format from Metadata depending on Prefix selected
            for(Phone_Format__mdt phoneFormat : [SELECT Id, Label, Format__c, Prefix__c, Regular_Expression__c FROM Phone_Format__mdt WHERE Prefix__c IN :setPhonePrefix]){
                if(mapPhoneFormat.containsKey(phoneFormat.Prefix__c)){
                    mapPhoneFormat.get(phoneFormat.Prefix__c).add(phoneFormat);
                } else {
                    mapPhoneFormat.put(phoneFormat.Prefix__c,new List<Phone_Format__mdt> {phoneFormat});
                }
            }
            
            if(mapPhoneFormat != null && mapPhoneFormat.size()>0){ 
                //Iterate all sObject data
                for(sObject phoneValidation :  lstNewData){
                    
                    //Call concatenatePrefixPhone method to concatenate Prefix and Number
                    concatenatePrefixPhone(lstFieldName, phoneValidation);
                    List<Phone_Format__mdt> lstPhoneFormat = new List<Phone_Format__mdt>();
                    
                    if((String.isNotBlank(mobilePrefix) && mapPhoneFormat.containsKey(mobilePrefix))|| 
                       (String.isNotBlank(phonePrefix) && mapPhoneFormat.containsKey(phonePrefix)))
                    {
                        //If both Mobile and Phone prefix same then we will consider only one prefix Metadata data else both prefix's data
                        if(mobilePrefix == phonePrefix){
                            lstPhoneFormat.addAll(mapPhoneFormat.get(mobilePrefix));
                        } else {
                            if(String.isNotBlank(mobilePrefix)){
                                lstPhoneFormat.addAll(mapPhoneFormat.get(mobilePrefix));                                  
                            } 
                            
                            if(String.isNotBlank(phonePrefix)){
                                lstPhoneFormat.addAll(mapPhoneFormat.get(phonePrefix));
                            }
                        }
                        
                        Boolean match = False;
                        String issueOnPhone = '';
                        System.debug(LoggingLevel.DEBUG,'lstPhoneFormat::'+lstPhoneFormat);
                        for(Phone_Format__mdt phoneMetadata : lstPhoneFormat){
                            
                            //Check whether the Metadata is of Mobile/Phone if any one of them does not match with the Regular Expresssion
                            //than it will immediately break from FOR Loop
                            if((phoneMetadata.Label).containsIgnoreCase('Mobile') && mobileNumber.containsIgnoreCase(phoneMetadata.Prefix__c)){
                                System.debug(LoggingLevel.DEBUG,'phoneMetadata:::'+phoneMetadata);
                                match = Pattern.matches(phoneMetadata.Regular_Expression__c, mobileNumber);
                                System.debug(LoggingLevel.DEBUG,'match mobile:::'+match);
                                if(!match){
                                    issueOnPhone = 'Mobile'+phoneMetadata.Format__c;
                                    break;
                                }
                                
                            } else if((phoneMetadata.Label).containsIgnoreCase('Phone') && phoneNumber.containsIgnoreCase(phoneMetadata.Prefix__c)){
                                System.debug(LoggingLevel.DEBUG,'phoneMetadata:::'+phoneMetadata);
                                System.debug(LoggingLevel.DEBUG,'phoneNumber:::'+phoneNumber);
                                match = Pattern.matches(phoneMetadata.Regular_Expression__c, phoneNumber);
                                System.debug(LoggingLevel.DEBUG,'match phone:::'+match);
                                if(!match){
                                    issueOnPhone = 'Phone'+phoneMetadata.Format__c;
                                    break;
                                }
                            }
                            
                        }
                        
                        //If Both mobile and phone matched with regular expression than populated the concatenate value in Field of sobject
                        //If not matched than throw error message and display the format maintain in the Metadata.
                        
                        if(match){
                            populatePhoneNumber(lstFieldToUpdate, phoneValidation);
                            System.debug(LoggingLevel.DEBUG,'phoneValidation on mobile::'+phoneValidation);                                    
                        } else if(!match && issueOnPhone.containsIgnoreCase('Phone')){
                            String errorMessage = Label.PhoneNumberMessage;
                            errorMessage = errorMessage.replace('XXXX', 'Phone');
                            phoneValidation.addError(errorMessage+' '+issueOnPhone.removeStart('Phone'));  // 145713
                        } else if(!match && issueOnPhone.containsIgnoreCase('Mobile')){
                            String errorMessage = Label.PhoneNumberMessage;
                            errorMessage = errorMessage.replace('XXXX', 'Mobile');
                            phoneValidation.addError(errorMessage+' '+issueOnPhone.removeStart('Mobile'));  // 145713
                        }
                        System.debug(LoggingLevel.DEBUG,'phoneValidation::'+phoneValidation);
                    }
                }                    
            }            
        }
    }
}