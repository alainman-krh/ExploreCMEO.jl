#base.jl: ExploreCMEO base structures and functionnality
#-------------------------------------------------------------------------------


#==Constants
===============================================================================#
const LIST_GRADEID = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]
#const MAXCOL_GRADEID = 7


#==Types
===============================================================================#
mutable struct ExploreSelection
	subject::String
	#zero-based indices:
	grade_idx::Int
	domain_idx::Int
	attente_idx::Int
#	content_idx::Int
end
ExploreSelection() = ExploreSelection("", 0, 0, 0)


#==
===============================================================================#
function _valididx(args...)
	for v in args
		if v < 1; return false; end
	end
	return true
end
function _getid_grade(grade_idx::Int)
	if grade_idx in (1:length(LIST_GRADEID))
		return LIST_GRADEID[grade_idx]
	else
		return ""
	end
end
_getid_domain(domain_idx::Int) = string('A'+(domain_idx-1))
getid_domain(domain_idx::Int) = (_valididx(domain_idx) ? _getid_domain(domain_idx) : "")
function _getid_attente(domain_idx::Int, attente_idx::Int)
	prefix = getid_domain(domain_idx)
	return "$prefix$attente_idx"
end
getid_attente(domain_idx::Int, attente_idx::Int) =
	(_valididx(domain_idx, attente_idx) ? _getid_attente(domain_idx, attente_idx) : "")
function _getid_content(domain_idx::Int, attente_idx::Int, content_idx::Int)
	prefix = _getid_attente(domain_idx, attente_idx)
	return "$prefix.$content_idx"
end
getid_content(domain_idx::Int, attente_idx::Int, content_idx::Int) =
	(_valididx(domain_idx, attente_idx, content_idx) ? _getid_content(domain_idx, attente_idx, content_idx) : "")


#Last line
