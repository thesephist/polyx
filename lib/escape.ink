` escaping various formats `

str := load('../vendor/str')
replace := str.replace

html := s => (
	s := replace(s, '<', '&lt;')
	s := replace(s, '>', '&gt;')
	s := replace(s, '&', '&amp;')
)
