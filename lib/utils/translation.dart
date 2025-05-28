// Translation utility for error and common messages
class AppTranslations {
  static const Map<String, String> _en = {
    // Error messages
    'invalid_email': 'Invalid email format.',
    'user_disabled': 'This account has been disabled.',
    'user_not_found': 'No user found with this email.',
    'wrong_password': 'Incorrect password.',
    'email_already_in_use': 'Email already in use.',
    'weak_password': 'Password is too weak.',
    'operation_not_allowed': 'Operation not allowed.',
    'unexpected_error': 'An unexpected error occurred. Please try again.',
    'sign_in_failed': 'Failed to sign in. Please try again.',
    'sign_out_error': 'Error signing out. Please try again.',
    'request_already_sent': 'Request already sent and pending.',
    'request_sent': 'Request sent!',
    'chat_request_accepted': 'Chat request accepted.',
    'chat_request_rejected': 'Chat request rejected.',
    // Common
    'signed_in_as': 'Signed in as: ',
    'please_enter_email_password': 'Please enter both email and password',
    'account_created': 'Account created: ',
    'no_users_found': 'No users found',
    'no_users_found_matching': 'No users found matching',
    'online': 'Online',
    'wants_to_chat': 'Wants to chat',
    'pending': 'Pending',
    'send': 'Send',
    'cancel': 'Cancel',
    'sign_in': 'Sign In',
    'sign_up': 'Sign Up',
    'already_have_account': 'Already have an account? Sign In',
    'dont_have_account': "Don't have an account? Sign Up",
  };

  static String tr(String key, {String? fallback, String? append}) {
    final value = _en[key] ?? fallback ?? key;
    if (append != null) {
      return value + append;
    }
    return value;
  }
}
