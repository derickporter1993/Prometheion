#!/bin/bash
# Script to update SLDS classes to design token format
# Usage: ./scripts/update-slds-tokens.sh

echo "Updating SLDS classes to design token format..."

# Find all HTML files in LWC directory
find force-app/main/default/lwc -name "*.html" -type f | while read file; do
    echo "Processing: $file"
    
    # Update padding classes
    sed -i '' 's/slds-p-around_medium/slds-var-p-around_medium/g' "$file"
    sed -i '' 's/slds-p-around_small/slds-var-p-around_small/g' "$file"
    sed -i '' 's/slds-p-around_large/slds-var-p-around_large/g' "$file"
    sed -i '' 's/slds-p-around_x-small/slds-var-p-around_x-small/g' "$file"
    
    # Update margin classes
    sed -i '' 's/slds-m-vertical_large/slds-var-m-vertical_large/g' "$file"
    sed -i '' 's/slds-m-vertical_small/slds-var-m-vertical_small/g' "$file"
    sed -i '' 's/slds-m-vertical_medium/slds-var-m-vertical_medium/g' "$file"
    sed -i '' 's/slds-m-bottom_small/slds-var-m-bottom_small/g' "$file"
    sed -i '' 's/slds-m-bottom_medium/slds-var-m-bottom_medium/g' "$file"
    sed -i '' 's/slds-m-bottom_large/slds-var-m-bottom_large/g' "$file"
    sed -i '' 's/slds-m-bottom_x-small/slds-var-m-bottom_x-small/g' "$file"
    sed -i '' 's/slds-m-top_small/slds-var-m-top_small/g' "$file"
    sed -i '' 's/slds-m-top_medium/slds-var-m-top_medium/g' "$file"
    sed -i '' 's/slds-m-top_large/slds-var-m-top_large/g' "$file"
    sed -i '' 's/slds-m-top_x-small/slds-var-m-top_x-small/g' "$file"
    sed -i '' 's/slds-m-left_small/slds-var-m-left_small/g' "$file"
    sed -i '' 's/slds-m-right_small/slds-var-m-right_small/g' "$file"
    sed -i '' 's/slds-m-right_x-small/slds-var-m-right_x-small/g' "$file"
done

echo "SLDS token update complete!"
echo "Note: Review changes before committing. Some classes may need manual adjustment."
