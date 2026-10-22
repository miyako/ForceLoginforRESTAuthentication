Class extends DataStoreImplementation

exposed Function authentify($credentiels : Object) : Boolean
	
	If ($credentiels#{})
		If (Validate password:C638($credentiels.name; $credentiels.password))
			If (User in group:C338($credentiels.name; "RestAccess"))
				return Session:C1714.setPrivileges("Admin")
			End if 
		End if 
	End if 
	
	
exposed Function hasPrivilege($nom : Text) : Boolean
	return Session:C1714.hasPrivilege($nom)
	
	
exposed Function getPrivileges() : Collection
	return Session:C1714.getPrivileges()
	
	