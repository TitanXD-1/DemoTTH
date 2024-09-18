/*
* @Name: EDGE_CSVFileGenerator
* @description: This class is used to generate csv file for robo excel
* @History                                                            

VERSION			AUTHOR					DATE					DETAIL
1.0			Saurav Prasad			07/07/2024				Initial Development: 152719 - SFDC Data mapping in Free Goods CSV for Robot Upload

*/
public with sharing class EDGE_CSVFileGenerator {
    
    public static String generateCSV(List<CellData> cellDataList) {
        // Find the maximum row and column to determine the size of the CSV
        Integer maxRow = 0;
        Integer maxCol = 0;
        
        for (CellData cellData : cellDataList) {
            if (cellData.row > maxRow) {
                maxRow = cellData.row;
            }
            if (cellData.col > maxCol) {
                maxCol = cellData.col;
            }
        }
        
        // Initialize the CSV matrix with empty strings
        List<List<String>> csvMatrix = new List<List<String>>();
        for (Integer rowCount = 0; rowCount <= maxRow; rowCount++) {
            List<String> row = new List<String>();
            for (Integer emptyRowCount = 0; emptyRowCount <= maxCol; emptyRowCount++) {
                row.add('');
            }
            csvMatrix.add(row);
        }
        
        // Populate the CSV matrix with the provided data
        for (CellData cellData : cellDataList) {
            csvMatrix[cellData.row][cellData.col] = cellData.data;
        }
        
        // Convert the CSV matrix to a string
        String csvContent = '';
        for (List<String> row : csvMatrix) {
            csvContent += String.join(row, ',') + '\n';
        }
        
        return csvContent.toString();
    }
    
    public class CellData {
        public Integer row;
        public Integer col;
        public String data;
        
        public CellData(Integer row, Integer col, String data) {
            this.row = row;
            this.col = col;
            this.data = data;
        }
    }
    
}