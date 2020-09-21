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
	content_idx::Int
end
ExploreSelection(subject::String="", grade=0, domain=0, attente=0, content=0) =
	ExploreSelection(subject, grade, domain, attente, content)

#Different views made up of one or more fields:
abstract type AbstractFieldView; end

struct FViewNone<:AbstractFieldView; end
struct FViewSrcDoc<:AbstractFieldView; end
struct FViewDomain<:AbstractFieldView; end
struct FViewAttente<:AbstractFieldView; end
struct FViewAttente_LongDescr<:AbstractFieldView; end
struct FViewContent<:AbstractFieldView; end

struct FieldViewOpts
	include_id::Bool #Ex: A1.1
	include_shortdescr::Bool
	include_longdescr::Bool
end
FieldViewOpts() = FieldViewOpts(true, true, true)


#==Create identifiers for different curriculum elements (ex: A1.1)
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
function _getid_attente(domain_idx::Int, attente_idx::Int)
	prefix = getid_domain(domain_idx)
	return "$prefix$attente_idx"
end
function _getid_content(domain_idx::Int, attente_idx::Int, content_idx::Int)
	prefix = _getid_attente(domain_idx, attente_idx)
	return "$prefix.$content_idx"
end
getid_domain(domain_idx::Int) = (_valididx(domain_idx) ? _getid_domain(domain_idx) : "")
getid_attente(domain_idx::Int, attente_idx::Int) =
	(_valididx(domain_idx, attente_idx) ? _getid_attente(domain_idx, attente_idx) : "")
getid_content(domain_idx::Int, attente_idx::Int, content_idx::Int) =
	(_valididx(domain_idx, attente_idx, content_idx) ? _getid_content(domain_idx, attente_idx, content_idx) : "")


#==Get identifiers for different field views
===============================================================================#
_getid(::AbstractFieldView) = ""
_getid(::FViewDomain) = "Domaine"
_getid(::FViewAttente) = "Attente"
_getid(::FViewAttente_LongDescr) = _getid(FViewAttente())
_getid(::FViewContent) = "Contenu d'Apprentissage"

_getid(::AbstractFieldView, sel::ExploreSelection) = ""
_getid(fv::FViewDomain, sel::ExploreSelection) =
	string(_getid(fv), " ", getid_domain(sel.domain_idx))
_getid(fv::FViewAttente, sel::ExploreSelection) =
	string(_getid(fv), " ", getid_attente(sel.domain_idx, sel.attente_idx))
_getid(fv::FViewAttente_LongDescr, sel::ExploreSelection) =
	_getid(FViewAttente(), sel)
_getid(fv::FViewContent, sel::ExploreSelection) =
	string(_getid(fv), " ", getid_content(sel.domain_idx, sel.attente_idx, sel.content_idx))


#==Accessing database file
===============================================================================#
function open_database(filepath::String, mode::String; log::Bool=true)
	filepath = abspath(filepath)
	db = HDF5.h5open(filepath, mode)
	@info("Données source:\n$(db.filename)")
	return db
end

#Last line
