import SwiftUI

struct BambooPackCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About BambooPack") {
                showAboutPanel()
            }
        }
    }
    
    private func showAboutPanel() {
        NSApplication.shared.orderFrontStandardAboutPanel(
            options: [
                .applicationName: "BambooPack",
                .version: "Animal Friends Edition",
                .credits: generateCreditsString()
            ]
        )
    }
    
    // private func generateCreditsString() -> NSAttributedString {
    //     // NOTE: The lines with standard text must have TWO SPACES at the end.
    //     let markdown = """
    //     Copyright © 2026, RedPanda Mochi
    //     Licensed under the MIT license
    //     See LICENSE file
        
    //     **Open Source**
    //     [GitHub Repository](https://github.com/Mochiredpanda/bamboo-pack)
        
    //     **Contact & Support**
    //     [mochiredpanda0@gmail.com](mailto:mochiredpanda0@gmail.com?subject=Bamboo%20Pack%20Feedback)
    //     """

    //     guard let str = try? NSMutableAttributedString(markdown: markdown) else {
    //         return NSAttributedString(string: "Copyright © 2026, RedPanda Mochi")
    //     }
        
    //     let wholeRange = NSRange(location: 0, length: str.length)
        
    //     // 1. Apply Layout and Gaps
    //     let paragraphStyle = NSMutableParagraphStyle()
    //     paragraphStyle.alignment = .center
    //     paragraphStyle.paragraphSpacing = 6
        
    //     str.addAttribute(.paragraphStyle, value: paragraphStyle, range: wholeRange)
    //     str.addAttribute(.foregroundColor, value: NSColor.labelColor, range: wholeRange)
        
    //     // 2. Safely resize fonts while preserving Markdown traits (Bold/Italic)
    //     let smallSize = NSFont.smallSystemFontSize
        
    //     str.enumerateAttribute(.font, in: wholeRange, options: []) { value, range, _ in
    //         if let currentFont = value as? NSFont {
    //             // Extract the existing descriptor (which holds the bold trait from Markdown)
    //             let fontDescriptor = currentFont.fontDescriptor
    //             // Create a new font retaining the bold trait, but with the smaller size
    //             if let newFont = NSFont(descriptor: fontDescriptor, size: smallSize) {
    //                 str.addAttribute(.font, value: newFont, range: range)
    //             }
    //         } else {
    //             // Fallback if no font trait exists on this chunk of text
    //             str.addAttribute(.font, value: NSFont.systemFont(ofSize: smallSize), range: range)
    //         }
    //     }
        
    //     return str
    // }

    private func generateCreditsString() -> NSAttributedString {
        let text = """
        Copyright © 2026, RedPanda Mochi
        Licensed under the MIT license
        See LICENSE file
        
        **Open Source**
        [GitHub Repository](https://github.com/Mochiredpanda/bamboo-pack)
        
        **Contact & Support**
        [mochiredpanda0@gmail.com](mailto:mochiredpanda0@gmail.com?subject=Bamboo%20Pack%20Feedback)
        """
        
        // 1. Configure modern parser to respect code line-breaks literally
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        
        guard let attrString = try? AttributedString(markdown: text, options: options) else {
            return NSAttributedString(string: "Copyright © 2026, RedPanda Mochi")
        }
        
        // 2. Convert to Objective-C NSAttributedString for the AppKit API
        let str = NSMutableAttributedString(attrString)
        let wholeRange = NSRange(location: 0, length: str.length)
        
        // 3. Apply center alignment
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        str.addAttribute(.paragraphStyle, value: paragraphStyle, range: wholeRange)
        str.addAttribute(.foregroundColor, value: NSColor.labelColor, range: wholeRange)
        
        // 4. Safely resize fonts while preserving Bold traits
        let smallSize = NSFont.smallSystemFontSize
        
        str.enumerateAttribute(.font, in: wholeRange, options: []) { value, range, _ in
            if let currentFont = value as? NSFont {
                let fontDescriptor = currentFont.fontDescriptor
                if let newFont = NSFont(descriptor: fontDescriptor, size: smallSize) {
                    str.addAttribute(.font, value: newFont, range: range)
                }
            } else {
                str.addAttribute(.font, value: NSFont.systemFont(ofSize: smallSize), range: range)
            }
        }
        
        return str
    }
}