echo "Be sure to check version number in haxelib.json:"
cat haxelib.json | grep -i version
echo "lib.haxe.org currently has:"
curl -s http://lib.haxe.org/p/gql2hx | grep 'Current version'
sleep 1
read -r -p "Are you sure? [y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
  rm -f gql2hx.zip
  zip -r gql2hx.zip graphql haxelib.json README.md
  zip -j gql2hx.zip ../LICENSE
  haxelib submit gql2hx.zip
else
  echo "Cancelled"
fi
