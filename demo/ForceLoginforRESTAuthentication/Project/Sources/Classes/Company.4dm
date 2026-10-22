Class extends DataClass

exposed Function getCompany() : Collection
	return This:C1470.Company.all().toCollection()
	
	
exposed Function getCompanyByName($name : Text) : Collection
	return This:C1470.query("companyName = :1"; $name).toCollection()