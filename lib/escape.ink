` escaping various formats `

str := load('../vendor/str')
replace := str.replace

html := s => (
	s := replace(s, '&', '&amp;')
	s := replace(s, '<', '&lt;')
)
