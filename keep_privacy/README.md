1. Copy semi_ephermal_mode.py to some where in you path.
2. Copy create-repo.sh to somewhere in you path.
Now, instead of do create-repo.sh and pass the user token ass parameter, you can 
    1. run semi_ephermal_mode.py  create-repo.sh 5 
    2. You are now passed into a subshell which have read your first argument and you can now paste  the needed args to the script, where one of them is your super secret token.
    3. Press enter, What you typed is gone, so the secret token will not get it into your history file. 

