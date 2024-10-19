public class InvoiceController {
    public String originRecord { get; set; }
    public String account { get; set; }
    public Date invoiceDate { get; set; }
    public Date invoiceDueDate { get; set; }
    public String childRelationshipName { get; set; }
    public String lineItemDescription { get; set; }
    public Integer lineItemQuantity { get; set; }
    public Decimal lineItemUnitPrice { get; set; }

    public InvoiceController() {
        originRecord = ApexPages.currentPage().getParameters().get('origin_record');
        account = ApexPages.currentPage().getParameters().get('account');
        invoiceDate = Date.valueOf(ApexPages.currentPage().getParameters().get('invoice_date'));
        invoiceDueDate = Date.valueOf(ApexPages.currentPage().getParameters().get('invoice_due_date'));
        childRelationshipName = ApexPages.currentPage().getParameters().get('child_relationship_name');
        lineItemDescription = ApexPages.currentPage().getParameters().get('line_item_description');
        lineItemQuantity = Integer.valueOf(ApexPages.currentPage().getParameters().get('line_item_quantity'));
        lineItemUnitPrice = Decimal.valueOf(ApexPages.currentPage().getParameters().get('line_item_unit_price'));
    }
}
