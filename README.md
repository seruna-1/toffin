# Tokenizable file tree interface (toffin)

Each dir node has 100 files and 10 other dir.

Each filename is the number id of its record in the table [Files], and each directory path is maped to a number id in the table [Directories]. Dirnames range from 0 to 9, whereas directory_id starts from 1, so [1/2/3] maps to the id 124. Filenames and file_id start from 10 to avoid conflict with dirnames.

## File creation

Specify a title and tokens.

The file will be put at an unfully directory. The lookup for the free directory is done by layers. The first layer has one directory, the root (space for 100 files). The second layer has 10 dirs (space for 100\*10 files), the third has 100 dirs (space for 100\*10\*10 files), and so on.

At each layer, the lookup goes in increasing route.
