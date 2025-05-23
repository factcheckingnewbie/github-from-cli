Use this after last commit, and before push.

It resolve paths for moved and/or renamed files that point do files in the same repo.
It uses git-tools, so it is only usable when working inside a repo.

# How to use.
1. Put the  scripts somewhere in yor systempath
2. Vefore you do a push: 

```
find-path-refereces.sh  | /scripts/update-paths.sh 
```

That will find files which you have moved/renamed and are pointerd to form other files. 
You are prompted it you want to update the paths. yes update the path, no skup to next file.

