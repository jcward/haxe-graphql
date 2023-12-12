#### Debug 

```
# vscode from project root
code -n .
```

The 'Launch via NPM' debug configuration will run the code in test/manual_debug/Test.hx

You can change the GQL you are attempting to generate code for by linking `test/manual_debug/test.gql` to the desired file.  This GQL text is available as a Resource in Haxe land by the hidden build file `${projectRoot}.vscode/debug.hxml`

```
# snip from debug.html .. note test.gql maps to the symbol is injected_gql
-resource test.gql@injected_gql
```