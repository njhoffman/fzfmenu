#compdef aws-vault

local curcontext="$curcontext" state line

_vault_cmds() {
	local -a commands
	commands=(
		'help:Show help'
		'add:Adds credentials, prompts if none provided'
		'list:List profiles, along with their credentials and sessions'
		'rotate:Rotates credentials'
		'exec:Executes a command with AWS credentials in the environment'
		'remove:Removes credentials, including sessions'
		'login:Generate a login link for the AWS Console'
	)
	_describe 'command' commands
}

_vault_profiles() {
	local -a profiles
	IFS=$'\n'
	profiles=($(aws-vault list --profiles))
	_describe 'PROFILE' profiles
}

_vault_credentials() {
	local -a creds
	IFS=$'\n'
	creds=($(aws-vault list --credentials))
	_describe 'CREDENTIALS' creds
}

local -A opt_args

_arguments -C \
	'1: :_vault_cmds' \
	'*:: :->args'

case "$state" in args)
	case $words[1] in
	login)
		_arguments \
			'--no-session[Use root credentials, no session created]' \
			'--mfa-token=[The mfa token to use]' \
			'--path=[The AWS service you would like access]' \
			'--federation-token-ttl=[Expiration time for aws console session]' \
			'--assume-role-ttl=[Expiration time for aws assumed role]' \
			'--stdout[Print login URL to stdout instead of opening in default browser]' \
			'1:PROFILE:_vault_profiles'
		;;
	exec)
		_arguments \
			'--no-session[Use root credentials, no session created]' \
			'--session-ttl=[Expiration time for aws session]' \
			'--assume-role-ttl=[Expiration time for aws assumed role]' \
			'--mfa-token=[The mfa token to use]' \
			'--mfa-serial-override=[Override the MFA Serial defined in AWS Profile]' \
			'--json[AWS credential helper.]' \
			'--server[Run the server in the background for credentials]' \
			'1:PROFILE:_vault_profiles'
		;;
	remove)
		_arguments \
			'--sessions-only[Only remove sessions, leave credentials intact]' \
			'1:CREDENTIALS:_vault_credentials'
		;;
	rotate)
		_arguments \
			'--mfa-token=[The mfa token to use]' \
			'1:CREDENTIALS:_vault_credentials'
		;;
	list)
		_arguments \
			'--profiles[Show only the profile names]' \
			'--sessions[Show only the session names]' \
			'--credentials[Show only the credential names]'
		;;
	add)
		_arguments \
			'--env[Read the credentials from the environment]' \
			"--add-config[Add a profile to ~/.aws/config if one doesn't exist]"
		;;
	esac
	;;
esac
