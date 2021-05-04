sfdx force:org:create -f config/project-scratch-def.json -a ActionPlans -s

sfdx force:source:push

sfdx force:user:permset:assign -n Action_Plans_Admin

sfdx force:org:open

#Version Increase Comment


#Deploy to ActionPlans Dev/Packaging Org: Use -c to check only first
#
#sfdx force:source:deploy -u ActionPlansDevOrg -w 100 -p force-app/main/default