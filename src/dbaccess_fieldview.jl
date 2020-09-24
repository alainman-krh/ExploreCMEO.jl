#dbaccess_fieldview.jl: Extra layer allowing use of <:AbstractFieldView accessors.
#-------------------------------------------------------------------------------


#==Constants
===============================================================================#
const MSG_CANNOTEDIT = "Impossible de modifier données sélectionnées!"
const ERROR_CANNOTEDIT = ArgumentError(MSG_CANNOTEDIT)
const MSG_CANNOTADD = "Impossible d'ajouter un item!"
const ERROR_CANNOTADD = ArgumentError(MSG_CANNOTADD)
const MSG_CANNOTREMOVE = "Impossible de supprimer l'item!"
const ERROR_CANNOTREMOVE = ArgumentError(MSG_CANNOTREMOVE)


#==Types
===============================================================================#
mutable struct FieldViewEditData{T<:AbstractFieldView}
	descr::String
	shortdescr::String
	has_shortdescr::Bool
end
FieldViewEditData(::T) where T<:AbstractFieldView = FieldViewEditData{T}("", "", false)
FieldViewEditData(::FViewAttente) = FieldViewEditData{FViewAttente}("", "", true)
FieldViewEditData(::FViewAttente_LongDescr) = FieldViewEditData(FViewAttente())
FieldViewEditData() = FieldViewEditData(FViewNone())


#==Helper functions
===============================================================================#
fieldviewvalue(::FieldViewEditData{T}) where T = T()

function cleardata(data::FieldViewEditData)
	data.descr = ""
	data.shortdescr = ""
end


#==_read functions for FieldViewEditData
===============================================================================#
function _read(data::FieldViewEditData, db::HDF5.HDF5File, sel::ExploreSelection)
	cleardata(data)
	throw(string(ERROR_CANNOTEDIT, ": $(fv)"))
	return
end
function _read(data::FieldViewEditData{FViewSrcDoc}, db::HDF5.HDF5File, sel::ExploreSelection)
	cleardata(data)
	try
		validateexists_grade(db, sel)
	catch
		createslot_srcdoc(db, sel) #Throws error if cannot
	end
	srcstr = read_sourcedoc(db, sel)
	if isnothing(srcstr); throw(ERROR_CANNOTEDIT); end
	data.descr = srcstr
	return
end
function _read(data::FieldViewEditData{FViewDomain}, db::HDF5.HDF5File, sel::ExploreSelection)
	cleardata(data)
	try
		validateexists_domain(db, sel)
	catch e
		if sel.domain_idx < 1
			createslot_domain(db, sel) #Throws error if cannot
		else
			rethrow(e)
		end
	end
	dlist = read_domain_list(db, sel)
	if isnothing(dlist); throw(ERROR_CANNOTEDIT); end
	sel.domain_idx = clamp(sel.domain_idx, 1, length(dlist))
	litem = dlist[sel.domain_idx]
	data.descr = litem[3]
	return
end
function _read(data::FieldViewEditData{FViewAttente}, db::HDF5.HDF5File, sel::ExploreSelection)
	cleardata(data)
	try
		validateexists_attente(db, sel)
	catch e
		if sel.attente_idx < 1
			createslot_attente(db, sel) #Throws error if cannot
		else
			rethrow(e)
		end
	end
	dlist = read_attente_list(db, sel)
	if isnothing(dlist); throw(ERROR_CANNOTEDIT); end
	sel.attente_idx = clamp(sel.attente_idx, 1, length(dlist))
	litem = dlist[sel.attente_idx]
	data.shortdescr = litem[3]
	data.descr = litem[4]
	return
end
function _read(data::FieldViewEditData{FViewContent}, db::HDF5.HDF5File, sel::ExploreSelection)
	cleardata(data)
	try
		validateexists_content(db, sel)
	catch e
		if sel.content_idx < 1
			createslot_content(db, sel) #Throws error if cannot
		else
			rethrow(e)
		end
	end
	dlist = read_content_list(db, sel)
	if isnothing(dlist); throw(ERROR_CANNOTEDIT); end
	sel.content_idx = clamp(sel.content_idx, 1, length(dlist))
	litem = dlist[sel.content_idx]
	data.descr = litem[3]
	return
end

#==_write functions for FieldViewEditData
===============================================================================#
function _write(data::FieldViewEditData, db::HDF5.HDF5File, sel::ExploreSelection)
	throw(string(ERROR_CANNOTEDIT, ": $(fv)"))
	return
end
function _write(data::FieldViewEditData{FViewSrcDoc}, db::HDF5.HDF5File, sel::ExploreSelection)
	validateexists_grade(db, sel)
	write_sourcedoc(db, sel, data.descr)
	return
end
function _write(data::FieldViewEditData{FViewDomain}, db::HDF5.HDF5File, sel::ExploreSelection)
	validateexists_domain(db, sel)
	write_domain_descr(db, sel, data.descr)
	return
end
function _write(data::FieldViewEditData{FViewAttente}, db::HDF5.HDF5File, sel::ExploreSelection)
	validateexists_attente(db, sel)
	write_attente_descr(db, sel, data.shortdescr, data.descr)
	return
end
function _write(data::FieldViewEditData{FViewContent}, db::HDF5.HDF5File, sel::ExploreSelection)
	validateexists_content(db, sel)
	write_content_descr(db, sel, data.descr)
	return
end


#==addentry() functions
===============================================================================#
addentry(::AbstractFieldView, db::HDF5.HDF5File, sel::ExploreSelection) =
	throw(ERROR_CANNOTADD)
addentry(::FViewDomain, db::HDF5.HDF5File, sel::ExploreSelection) =
	createslot_domain(db, sel)
addentry(::FViewAttente, db::HDF5.HDF5File, sel::ExploreSelection) =
	createslot_attente(db, sel)
addentry(::FViewAttente_LongDescr, db::HDF5.HDF5File, sel::ExploreSelection) =
	createslot_attente(db, sel)
addentry(::FViewContent, db::HDF5.HDF5File, sel::ExploreSelection) =
	createslot_content(db, sel)


#==removelastentry() functions
===============================================================================#
function _removelastentry(grp, sel::ExploreSelection)
	if isnothing(grp); throw(ERROR_CANNOTREMOVE); end
	nelem = reada_nelem(grp)
	if nelem < 1; throw(ERROR_CANNOTREMOVE); end
	HDF5.o_delete(grp, "$nelem"); nelem -= 1
	writea_nelem(grp, collect(1:nelem))
	return
end
removelastentry(::AbstractFieldView, db::HDF5.HDF5File, sel::ExploreSelection) =
	throw(ERROR_CANNOTREMOVE)
function removelastentry(::FViewDomain, db::HDF5.HDF5File, sel::ExploreSelection)
	grp = gopen_nothing(db, getpath_domains(sel))
	_removelastentry(grp, sel)
end
function removelastentry(::FViewAttente, db::HDF5.HDF5File, sel::ExploreSelection)
	grp = gopen_nothing(db, getpath_attentes(sel))
	_removelastentry(grp, sel)
end
removelastentry(::FViewAttente_LongDescr, db::HDF5.HDF5File, sel::ExploreSelection) =
	removelastentry(FViewAttente(), db, sel)
function removelastentry(::FViewContent, db::HDF5.HDF5File, sel::ExploreSelection)
	grp = gopen_nothing(db, getpath_content(sel))
	_removelastentry(grp, sel)
end
isremovable(::AbstractFieldView) = false
isremovable(::Union{FViewDomain,FViewAttente,FViewAttente_LongDescr,FViewContent}) = true

#Last line
