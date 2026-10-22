//%attributes = {}
C_OBJECT:C1216($company)

$company:=ds:C1482.Company.new()
$company.companyName:="OpenAI"
$company.email:="contact@openai.com"
$company.city:="San Francisco"
$company.createdAt:=Current date:C33

$company.save()