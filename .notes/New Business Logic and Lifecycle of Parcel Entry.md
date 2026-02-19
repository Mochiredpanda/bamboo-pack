New Business Logic and Lifecycle of Parcel Entry

1. Definition: Parcel Entry is the item of a package created by users:
- it has 2 dimensions: Tracking Status, Shipping Status
- Tracking Status is a data level, boolean type: No Tracking Number -> Has Tracking Number
- Shipping Status is the logistic level, the real lifecycle of the entry: Pre-shipment → In Transit → Out for Delivery → Delivered → Exception; must have a tracking number to hold this level; Link a tracking number with a "history" log
- Attributes from User: Direction (Incoming / Outgoing); Name (User input); Carrier (by default auto-detect; allow user to decide); tracking number (if bool == Y, classified to "Shipped", else, "Waiting for Shipment"); Notes (User Input)
- Attributes maintained by app: Shipping Status (API or scraped from manual updates); Shipping History Log; Created At; Last Updated At; Expected Delivery Date（If available by API or scraper）
- Some scalable Attributes in the next iteration for outgoing: Purpose（Gift / Return & Exchange / Business / Personal); Recipient（optional)
- An entry model: id, name, direction, carrier, trackingNumber, shippingStatus, notes, createdAt, updatedAt, expectedDelivery
- scalable to outgoing entries: purpose, recipient, declaredValue, relatedOrderRef (connect this to incoming entry who has an order number, designed for return)
- exception: once the entry is linked with the Shipping Status (second dimension), on the UX level, does not allow user to delete the tracking number (making the first dimension became N from Y), only allow user to modify, cannot delete or clear and save. Just for safe, if an entry became N to Y on the status level, do not delete or unlink the shippment level and related data, freeze it and categorize it to "suspended".

2. Lifecycle design

- Incoming Entry lifecycle: 
[Ordered] ──input tracking ──▶ [Pre-shipment] ──▶ [In Transit] ──▶ [Out for Delivery] ──▶ [Delivered]
◀── [Exception]

- The Ordered Status already implemented, is a special status, which does not belong to part of the lifecycle, pre-lifecycle. Use separate UI like a special icon to hint, this is an entry incomplete.

- Outgoing Entry lifecycle:
[Draft] ──已寄出──▶ [Pre-shipment] ──▶ [In Transit] ──▶ [Delivered to recipient]
Archive
- Similar to Ordered, Outgoing also have a Draft status, suggesting that, "I am going to do this, I have (not) got the shipping label, I have (not) dropped that parcel."



3. UX design
- The current implement mixed Ordered and Shipped together. Redesign this, on the ParcelListView, implement a dynamic divider with a dim color to divide them, some are "to be activated", some are on the way (correctly in the lifecycle), delivered (not archived yet, green UI), exceptions (need attention, red UI). If found any entry under those categories, display those in the divider; if not, hide the divider has no corresponding entries. 
- Tracking number to be completed: if a user update the tracking number in a "Waiting for Shipment" entry, this is a key operation to change status on the "Tracking Status" dimension, then link the "Shipping Status" logistic level with this entry, entering the lifecycle as we defined. When the status changed, trigger an update scrape.
- After entry became delivered, do not archive, but categorize to the Delivered divider on the list. By default, archive after 30 days, or let the user decide to archive manually (right click or under detailView page)







