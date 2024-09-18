public class EDGE_LabelTranslatorController {

    public String label_lang {get;set;}
    public String label {get;set;}
    public List<String> labels {get;set;}
    public Integer labelListSize {get;set;}
    
    public  EDGE_LabelTranslatorController(){
       	Map<String, String> reqParams = ApexPages.currentPage().getParameters(); 
       	label_lang = reqParams.get('label_lang');
       	
        if(reqParams.get('labels') != null){
            String jsonListStr = reqParams.get('labels');
        	labels = (List<String>)JSON.deserialize(jsonListStr, List<String>.class);
            if(labels != null && labels.size() > 0){
            	labelListSize = labels.size();  
            }
        }
        System.debug('labels = '+ labels);
        
        //label = reqParams.get('label');
        //System.debug('label = '+ label);

    }
}