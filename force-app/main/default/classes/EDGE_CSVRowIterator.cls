/**********************************************************************
  Name : EDGE_CSVRowIterator
=======================================================================
  Purpose : This Class is used to Iterate a CSV File
=======================================================================
    History                                                            
------------------------------------------------------------------------                                                            
    VERSION    AUTHOR            DATE              DETAIL
     1.0      Saurav K Paul    21-02-2019        Initial Development
***********************************************************************/ 
public with sharing class EDGE_CSVRowIterator implements Iterator<String>, Iterable<String> {
    private String rows;
    private Integer index = 0;
    private String rowDelimiter = '\n';
    
    //Constructor
    public EDGE_CSVRowIterator(String csvRows){
        rows = csvRows;
    }
    //Constructor
	public EDGE_CSVRowIterator(String csvRows, String rowDelimiter){
        rows = csvRows;
        rowDelimiter = rowDelimiter;
    }
    //Method Name : hasNext
    public Boolean hasNext(){
        return index < rows.length() ? true : false;
    }
    //Method Name : next
    public String next(){
        Integer key = rows.indexOf(rowDelimiter, index);
        if (key == -1){
            key = rows.length();
        }
        String row = rows.subString(index, key);
        index = key + 1;
        return row;
    }
    //Method Name : Iterator
    public Iterator<String> iterator(){
        return this;
    }
}