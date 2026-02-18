This is a classic "MVP to Product" transition challenge. Your current "AI vibing" implementation suffers from **Information Overload**. It tries to show everything (Tracking ID, Date, Carrier, Status Text, Title) with equal visual weight, resulting in a cluttered interface where nothing stands out.

Here is a critical review and a redesigned solution focusing on the "Concise Hero" concept.

### **1\. Critical UX & Business Logic Review**

* **The "Tracking Number" Problem:** Displaying 1ZWE719... in the list view is the biggest UX mistake here.  
  * *Business Logic:* No human reads a tracking number to identify a package. They read "New Shoes" or "Amazon Order."  
  * *Fix:* Hide the tracking number completely in the list. Only show it in the Detail View (copy/paste scenario).  
* **Status Ambiguity:**  
  * *Business Logic:* "Shipped" and "Ordered" are fundamentally different states. "Ordered" means *passive waiting* (merchant processing). "Shipped" means *active movement* (logistics).  
  * *Fix:* Differentiate them visually. "Ordered" should look static/gray; "Shipped" should look active/blue or green.  
* **The "When?" Question:**  
  * *UX:* "Feb 16, 2026" forces the user to do mental math. "Is that today? Tomorrow?"  
  * *Fix:* Use **Relative Time**. Display "Arriving Tomorrow," "In 3 Days," or "Delivered 2h ago."  
* **Incoming vs. Outgoing:**  
  * *Business Logic:* An outgoing return needs different urgency than an incoming gift.  
  * *Fix:* Use icon variations (box with arrow down vs. arrow up) to reinforce direction, even inside specific categories.

### ---

**2\. The Solution: "The Intelligent Row"**

We will shift from a "Data Row" to a "Status Row."

1. **Left:** Visual identifier (Icon) \+ Title \+ Carrier.  
2. **Right:** The "Hero" data (Time remaining or Status).

#### **Updated ParcelRowView.swift**

I have added logic to calculate relative dates and cleaned up the layout to be much more scannable.

Swift

import SwiftUI

struct ParcelRowView: View {  
    @ObservedObject var parcel: Parcel  
      
    var body: some View {  
        HStack(alignment: .center, spacing: 14) {  
            // 1\. DYNAMIC ICON  
            // Visual cue for status & direction  
            ZStack {  
                Circle()  
                    .fill(statusColor.opacity(0.15))  
                    .frame(width: 42, height: 42) // Slightly larger touch target  
                  
                Image(systemName: iconName)  
                    .font(.system(size: 18, weight: .medium))  
                    .foregroundColor(statusColor)  
            }  
              
            // 2\. MAIN INFO (Title & Carrier)  
            VStack(alignment: .leading, spacing: 3) {  
                Text(parcel.title ?? "Untitled Parcel")  
                    .font(.body) // Standard readable size  
                    .fontWeight(.semibold)  
                    .foregroundColor(.primary)  
                    .lineLimit(1)  
                  
                HStack(spacing: 6) {  
                    // Carrier Tag  
                    if let carrier \= parcel.carrier, \!carrier.isEmpty, carrier \!= "Auto" {  
                        Text(carrier.uppercased())  
                            .font(.system(size: 9, weight: .bold))  
                            .padding(.horizontal, 6)  
                            .padding(.vertical, 2)  
                            .background(Color.secondary.opacity(0.1))  
                            .cornerRadius(4)  
                            .foregroundColor(.secondary)  
                    }  
                      
                    // Fallback description if no carrier  
                    if parcel.statusEnum \== .ordered {  
                        Text("Order Placed")  
                            .font(.caption)  
                            .foregroundColor(.secondary)  
                    }  
                }  
            }  
              
            Spacer()  
              
            // 3\. HERO STATUS (Right Side)  
            // Prioritizes "Time" or "Action" over raw dates  
            VStack(alignment: .trailing, spacing: 2) {  
                if parcel.statusEnum \== .delivered {  
                    Text("Delivered")  
                        .font(.callout)  
                        .fontWeight(.bold)  
                        .foregroundColor(.green)  
                      
                    // Show relative time for delivered items (e.g. "Yesterday")  
                    if let date \= parcel.lastUpdated {  
                        Text(date.formatted(.relative(presentation: .named)))  
                            .font(.caption2)  
                            .foregroundColor(.secondary)  
                    }  
                } else if parcel.statusEnum \== .ordered {  
                    // For ordered items, there is no delivery date yet  
                    Text("Processing")  
                        .font(.callout)  
                        .fontWeight(.medium)  
                        .foregroundColor(.secondary)  
                } else {  
                    // ACTIVE SHIPMENT logic  
                    // If we had an 'estimatedDeliveryDate', we would calculate "In 3 Days"  
                    // Since we only have lastUpdated in MVP, we show status clearly  
                    Text(parcel.statusEnum.title)  
                        .font(.callout)  
                        .fontWeight(.medium)  
                        .foregroundColor(.blue)  
                      
                    // Mocking the "Time Remaining" logic for the UX demo  
                    // In a real app, replace this with \`estimatedDeliveryDate\` logic  
                    Text("Arriving Soon")   
                        .font(.caption2)  
                        .foregroundColor(.secondary)  
                }  
            }  
        }  
        .padding(.vertical, 6) // Breathing room  
    }  
      
    // MARK: \- Computed Properties for Logic  
      
    var statusColor: Color {  
        switch parcel.statusEnum {  
        case .delivered: return .green  
        case .shipped: return .blue  
        case .ordered: return .gray // Neutral for "not moving yet"  
        case .exception: return .red // Important alert color  
        default: return .blue  
        }  
    }  
      
    var iconName: String {  
        // Business Logic: Differentiate direction visual  
        if parcel.direction \== .outgoing {  
            return "arrow.up.cube" // Outgoing icon  
        }  
          
        switch parcel.statusEnum {  
        case .delivered: return "checkmark" // Clear success indicator  
        case .ordered: return "cart" // Shopping context  
        case .shipped: return "truck.box" // Transit context  
        default: return "cube"  
        }  
    }  
}

### **3\. Key Improvements Explained**

#### **A. The "Clean" Information Hierarchy**

* **Removed:** Tracking Number. This instantly de-cluttered the view.  
* **Removed:** Raw Date (e.g., "Feb 16, 2026").  
* **Added:** Carrier Badge (small, pill-shaped) next to the title. This groups "Who" (Carrier) with "What" (Title).

#### **B. Dynamic Icons (Business Logic)**

Instead of a generic box for everything, the code now adapts the icon to the *reality* of the package:

* **Incoming/Shipped:** truck.box (implies movement).  
* **Outgoing:** arrow.up.cube (implies sending away).  
* **Delivered:** checkmark (implies completion).  
* **Ordered:** cart (implies a purchase, not a shipment yet).

#### **C. The "Hero" Right Side**

The right side of the row is now dedicated to the **Answer**, not the Data.

* If it's **Delivered**: It says "Delivered" in Green.  
* If it's **Active**: It says "Arriving Soon" (or "In 2 Days" if you add that data field) in Blue.  
* If it's **Ordered**: It says "Processing" in Gray.

### **4\. Next Step Recommendation (Data Model)**

To fully realize the "Hero" card potential, you need to add one field to your CoreData Parcel entity: **estimatedDeliveryDate**.

Once you have that, you can change the Right Side logic to:

Swift

if let date \= parcel.estimatedDeliveryDate {  
    let days \= Calendar.current.dateComponents(\[.day\], from: Date(), to: date).day ?? 0  
    if days \== 0 { Text("Today").foregroundColor(.orange) }  
    else if days \== 1 { Text("Tomorrow") }  
    else { Text("In \\(days) days") }  
}

This creates that "Amazon-like" concise urgency you are looking for.