import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({
    super.key,
    required this.submitFn,
    required this.isLoading,
  });

  final bool isLoading;
  final void Function(
    String email,
    String password,
    String userName,
    String vpa,
    bool isLogin,
    BuildContext ctx,
  ) submitFn;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<ShadFormState>();
  bool _obscure = true;
  var _isLogin = true;
  var _userEmail = '';
  var _userName = '';
  var _userPassword = '';
  var _vpa = '';

  void _trySubmit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    FocusScope.of(context).unfocus();
    _userEmail = _formKey.currentState?.value['email'] as String;
    _userPassword = _formKey.currentState?.value['password'] as String;
    if (!_isLogin) {
      _userName = _formKey.currentState?.value['username'] as String;
      _vpa = _formKey.currentState?.value['vpa'] as String;
    }
    if (isValid) {
      _formKey.currentState!.save();
      widget.submitFn(_userEmail.trim(), _userPassword.trim(), _userName.trim(),
          _vpa.trim(), _isLogin, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ShadForm(
          key: _formKey,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                ShadInputFormField(
                  id: 'email',
                  leading: const Icon(LucideIcons.mail),
                  label: const Text('Email'),
                  placeholder: const Text('Enter your email'),
                  validator: (v) {
                    if (!v.contains('@')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (!_isLogin)
                  ShadInputFormField(
                    id: 'username',
                    leading: const Icon(LucideIcons.user),
                    label: const Text('Username'),
                    placeholder: const Text('Enter your Username'),
                    validator: (v) {
                      if (v.isEmpty) {
                        return 'Please enter a valid username.';
                      }
                      return null;
                    },
                  ),
                if (!_isLogin) const SizedBox(height: 16),
                if (!_isLogin)
                  ShadInputFormField(
                    id: 'vpa',
                    label: const Text('VPA'),
                    leading: const Icon(LucideIcons.creditCard),
                    placeholder: const Text('Enter your VPA'),
                    validator: (v) {
                      if (v.isEmpty || !v.contains('@')) {
                        return 'Please enter a valid VPA.';
                      }
                      return null;
                    },
                  ),
                if (!_isLogin) const SizedBox(height: 16),
                ShadInputFormField(
                  id: 'password',
                  obscureText: _obscure,
                  leading: const Icon(LucideIcons.lock),
                  label: const Text('Password'),
                  placeholder: const Text('Enter your Password'),
                  validator: (v) {
                    if (v.length < 7) {
                      return 'Password must be at least 7 characters.';
                    }
                    return null;
                  },
                  trailing: ShadIconButton(
                    width: 24,
                    height: 24,
                    padding: EdgeInsets.zero,
                    decoration: const ShadDecoration(
                      secondaryBorder: ShadBorder.none,
                      secondaryFocusedBorder: ShadBorder.none,
                    ),
                    icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye),
                    onPressed: () {
                      setState(() => _obscure = !_obscure);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ShadButton(
                  width: double.infinity,
                  onPressed: _trySubmit,
                  child: Text(_isLogin ? 'Login' : 'Sign Up'),
                ),
                const SizedBox(height: 16),
                const Divider(),
                ShadButton.link(
                  width: double.infinity,
                  child: Text("Forgot your password?"),
                ),
                ShadButton.link(
                  width: double.infinity,
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(_isLogin
                      ? 'Create new account'
                      : 'Already Have an Account?'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
