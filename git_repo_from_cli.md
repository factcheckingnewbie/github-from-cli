1. curl/create-repo.sh <args>
2. git init
3. git add .
4. git commit -m "Initial commit"
5. git remote add origin https://github.com/your-username/your-repo.git
6. git branch --show-current
7. git push -u origin main

# If you made some spellingerror when creating the repo
1. git remote set-url origin https://github.com/correct_username/your-repo.git
2. verify (Not a must, but good to do)
    * git remote -v
3. git push -u origin main

