/**********************************************************************
  Name : EDGE_CSVFileParser
=======================================================================
  Purpose : This Class is used to Parse a CSV File
=======================================================================
    History                                                            
------------------------------------------------------------------------                                                            
    VERSION    AUTHOR            DATE              DETAIL
     1.0      Saurav K Paul    21-02-2019        Initial Development
***********************************************************************/ 
public with sharing class EDGE_CSVFileParser {
    public Integer rowCount ;
    public Integer colCount ;
    public List<List<String>> parsedCSV ;
   
    //Method Name : getResults
    //Description : It will parse CSV file and provide the data as collection of List with String as type
    public List<List<String>> getResults(string csvString) {
        system.debug('@@Inside getResults ' + csvString);
        parsedCSV = new List<List<String>>();
        rowCount = 0;
        colCount = 0;
        if (csvString != null){
            String fileString = csvString;
            parsedCSV = parseCSV(fileString, false);
            rowCount = parsedCSV.size();
            for (List<String> row : parsedCSV){
                if(row.size() > colCount){
                    colCount = row.size();
                }
            }
        }
        return parsedCSV;
    }
    
    //Method Name : parseCSV
    //Description : It will parse CSV file
    public static List<List<String>> parseCSV(String contents,Boolean skipHeaders) {
        List<List<String>> allFields = new List<List<String>>();
    
        // replace instances where a double quote begins a field containing a comma
        // in this case you get a double quote followed by a doubled double quote
        // do this for beginning and end of a field
        contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
        // now replace all remaining double quotes - we do this so that we can reconstruct
        // fields with commas inside assuming they begin and end with a double quote
        contents = contents.replaceAll('""','DBLQT');
        // we are not attempting to handle fields with a newline inside of them
        // so, split on newline to get the spreadsheet rows
        List<String> lines = new List<String>();
        try{
            //lines = contents.split('\n'); //correction: this only accomodates windows files
            lines = contents.split('\n'); // using carriage return accomodates windows, unix, and mac files
            //http://www.maxi-pedia.com/Line+termination+line+feed+versus+carriage+return+0d0a
        }catch (System.ListException e) {
            System.debug('Limits exceeded?' + e.getMessage());
        }
        Integer num = 0;
        for(String line: lines){
            // check for blank CSV lines (only commas)
            if (line.replaceAll(',','').trim().length() == 0){
                break;
            } 
            
            List<String> fields = line.split(',');  
            List<String> cleanFields = new List<String>();
            String compositeField;
            Boolean makeCompositeField = false;
            for(String field: fields) {
                if (field.startsWith('"') && field.endsWith('"')) {
                    cleanFields.add(field.replaceAll('DBLQT',''));
                }else if(field.startsWith('"')) {
                    makeCompositeField = true;
                    compositeField = field;
                }else if(field.endsWith('"')) {
                    compositeField += ',' + field;
                    cleanFields.add(compositeField.replaceAll('DBLQT',''));
                    makeCompositeField = false;
                }else if(makeCompositeField) {
                    compositeField +=  ',' + field;
                } else{
                    cleanFields.add(field.replaceAll('DBLQT',''));
                }
            }
            allFields.add(cleanFields);
        }
        if(skipHeaders){
			allFields.remove(0);
        } 
        return allFields;       
    }
}