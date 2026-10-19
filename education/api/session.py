import frappe
from frappe import _


@frappe.whitelist(allow_guest=True)
def get_session_user():
	"""Return basic info about the currently logged-in user."""
	if frappe.session.user == "Guest":
		frappe.throw(_("Not logged in"), frappe.AuthenticationError)

	return {
		"user": frappe.session.user,
		"full_name": frappe.db.get_value("User", frappe.session.user, "full_name"),
		"user_image": frappe.db.get_value("User", frappe.session.user, "user_image"),
	}


@frappe.whitelist()
def logout():
	"""Log out the current user and clear their session."""
	frappe.local.login_manager.logout()
	frappe.db.commit()
