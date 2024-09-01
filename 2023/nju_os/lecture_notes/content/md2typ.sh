find . -type f -name "*.md" -exec sh -c 'mv "$1" "${1%.md}.typ"' _ {} \;

sed -i 's/##### /===== /g' *.typ
sed -i 's/#### /==== /g' *.typ
sed -i 's/### /=== /g' *.typ
sed -i 's/## /== /g' *.typ
sed -i 's/# /= /g' *.typ

sed -i 's/!\[\](\([^)]*\))/#image("\1")/g' *.typ

sed -i 's/\*\*/\*/g' *.typ
sed -i 's/\$\$/\$/g' *.typ

sed -i 's/\\geq/gt.eq/g' *.typ   
sed -i 's/\\sum/sum/g' *.typ     
sed -i 's/\\Delta/Delta/g' *.typ 
sed -i 's/\\oplus/xor/g' *.typ   
sed -i 's/\\cdot/dot.op/g' *.typ 
sed -i 's/\\mod/"mod"/g' *.typ   

sed -i '1i\#import "../template.typ": *\n#pagebreak()' *.typ
