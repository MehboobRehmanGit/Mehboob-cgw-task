public class InvoiceController {
    public String originRecord { get; set; }
    public String account { get; set; }
    public String invoiceDate { get; set; }
    public String invoiceDueDate { get; set; }
    public String childRelationshipName { get; set; }
    public String lineItemDescription { get; set; }
    public String lineItemQuantity { get; set; }
    public String lineItemUnitPrice { get; set; }
    public String jsonResponse { get; set; }
    
    
    public InvoiceController() {
        originRecord = ApexPages.currentPage().getParameters().get('origin_record');
        account = ApexPages.currentPage().getParameters().get('account');
        invoiceDate = ApexPages.currentPage().getParameters().get('invoice_date');
        invoiceDueDate = ApexPages.currentPage().getParameters().get('invoice_due_date');
        childRelationshipName = ApexPages.currentPage().getParameters().get('child_relationship_name');
        lineItemDescription = ApexPages.currentPage().getParameters().get('line_item_description');
        lineItemQuantity = ApexPages.currentPage().getParameters().get('line_item_quantity');
        lineItemUnitPrice = ApexPages.currentPage().getParameters().get('line_item_unit_price');
        
    }
    
    public void generateInvoiceJSON() {
        try {
           List<Map<String, Object>> jsonLineItems = new List<Map<String, Object>>();

            String Pquery = 'SELECT ' + account + ', ' + invoiceDate + ', ' + invoiceDueDate + 
                ' FROM Opportunity WHERE Id = :originRecord';
            Opportunity opp = Database.query(Pquery);
             Map<String, Object> lineItemData = new Map<String, Object>();
                
            
            String query = 'SELECT ' + lineItemDescription + ', ' + lineItemQuantity + ', ' + lineItemUnitPrice +
                ' FROM ' + childRelationshipName + ' WHERE OpportunityId = :originRecord';
            List<SObject> lineItems = Database.query(query);
            
            for (SObject item : lineItems) {
                
                lineItemData.put('unitPrice', item.get(lineItemUnitPrice));
                lineItemData.put('description', item.get(lineItemDescription));
                lineItemData.put('quantity', item.get(lineItemQuantity));
                lineItemData.put('Invoive Due Date', opp.get(invoiceDueDate));
                lineItemData.put('Invoive Date', opp.get(invoiceDate));
                lineItemData.put('Account', opp.get(account));

                jsonLineItems.add(lineItemData);
            }
            
            // Serialize line items into JSON
            Map<String, Object> jsonResponseMap = new Map<String, Object>();
            jsonResponseMap.put('lineItems', jsonLineItems);
            jsonResponse = JSON.serializePretty(jsonResponseMap);
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error generating JSON: ' + e.getMessage()));
        }
    }
    
 
    public PageReference createInvoice() {
        try {
            String Pquery = 'SELECT ' + account + ', ' + invoiceDate + ', ' + invoiceDueDate +' FROM Opportunity WHERE Id = :originRecord';
            Opportunity opp = Database.query(Pquery);
            
            Invoice__c invoice = new Invoice__c();
            invoice.Account__c = opp.AccountId;
            invoice.Invoice_Date__c = opp.CloseDate;
            invoice.Due_Date__c = opp.Due_Date__c;
            insert invoice;
            
            String query = 'SELECT ' + lineItemDescription + ', ' + lineItemQuantity + ', ' + lineItemUnitPrice +
                ' FROM ' + childRelationshipName + ' WHERE OpportunityId = :originRecord';
            
            List<SObject> lineItems = Database.query(query);
            
            
            List<Invoice_Line_Item__c> lineItemsToInsert = new List<Invoice_Line_Item__c>();
            for (SObject item : lineItems) {
                Invoice_Line_Item__c lineItem = new Invoice_Line_Item__c();
                lineItem.Invoice__c = invoice.Id;
                lineItem.Description__c = (String)item.get(lineItemDescription);
                lineItem.Quantity__c = (Decimal)item.get(lineItemQuantity);
                lineItem.Unit_Price__c = (Decimal)item.get(lineItemUnitPrice);
                lineItemsToInsert.add(lineItem);
            }
            
            insert lineItemsToInsert;
            
            return new PageReference('/' + invoice.Id);
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error creating Invoice: ' + e.getMessage()));
            return null;
        }
    }
}
