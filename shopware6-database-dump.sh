#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o errtrace
set -o pipefail
IFS=$'\n\t'

###############################################################################
# Environment
###############################################################################

_ME="$(basename "${0}")"

###############################################################################
# Debug
###############################################################################

# _debug()
#
# Usage:
#   _debug <command> <options>...
#
# Description:
#   Execute a command and print to standard error. The command is expected to
#   print a message and should typically be either `echo`, `printf`, or `cat`.
#
# Example:
#   _debug printf "Debug info. Variable: %s\\n" "$0"
__DEBUG_COUNTER=0
_debug() {
  if ((${_USE_DEBUG:-0}))
  then
    __DEBUG_COUNTER=$((__DEBUG_COUNTER+1))
    {
      # Prefix debug message with "bug (U+1F41B)"
      printf "🐛  %s " "${__DEBUG_COUNTER}"
      "${@}"
      printf "―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――\\n"
    } 1>&2
  fi
}

###############################################################################
# Error Messages
###############################################################################

_exit_1() {
  {
    printf "%s " "$(tput setaf 1)!$(tput sgr0)"
    "${@}"
  } 1>&2
  exit 1
}
_warn() {
  {
    printf "%s " "$(tput setaf 1)!$(tput sgr0)"
    "${@}"
  } 1>&2
}

###############################################################################
# Help
###############################################################################

_print_help() {
  cat <<HEREDOC
Dumps a Shopware 6 database with a bit of cleanup and a GDPR mode ignoring more data.

Usage:
  ${_ME} [filename.sql] --database db_name --user username [--host 127.0.0.1] [--port 3306] [--gdpr]
  ${_ME} [filename.sql] -d db_name -u username [-H 127.0.0.1] [-p 3306] [--gdpr]
  ${_ME} -h | --help

Arguments:
  filename.sql   Set output filename, will be gzipped, dump.sql by default

Options:
  -h --help      Display this help information.
  -d --database  Set database name
  -u --user      Set database user name
  -H --host      Set hostname for database server (default: 127.0.0.1)
  -p --port      Set database server port (default: 3306)
  --gdpr         Enable GDPR data filtering
HEREDOC
}

###############################################################################
# Options
###############################################################################

# Parse Options ###############################################################

# Initialize program option variables.
_PRINT_HELP=0
_USE_DEBUG=0

# Initialize additional expected option variables.
_OPTION_GDPR=0
_DATABASE=
_HOST=127.0.0.1
_PORT=3306
_USER=

__get_option_value() {
  local __arg="${1:-}"
  local __val="${2:-}"

  if [[ -n "${__val:-}" ]] && [[ ! "${__val:-}" =~ ^- ]]
  then
    printf "%s\\n" "${__val}"
  else
    _exit_1 printf "%s requires a valid argument.\\n" "${__arg}"
  fi
}

while ((${#}))
do
  __arg="${1:-}"
  __val="${2:-}"

  case "${__arg}" in
    -h|--help)
      _PRINT_HELP=1
      ;;
    --debug)
      _USE_DEBUG=1
      ;;
    --gdpr)
      _OPTION_GDPR=1
      ;;
    -d|--database)
      _DATABASE="$(__get_option_value "${__arg}" "${__val:-}")"
      shift
      ;;
    -u|--user)
      _USER="$(__get_option_value "${__arg}" "${__val:-}")"
      shift
      ;;
    -H|--host)
      _HOST="$(__get_option_value "${__arg}" "${__val:-}")"
      shift
      ;;
    -p|--port)
      _PORT="$(__get_option_value "${__arg}" "${__val:-}")"
      shift
      ;;
    --endopts)
      # Terminate option parsing.
      break
      ;;
    -*)
      _exit_1 printf "Unexpected option: %s\\n" "${__arg}"
      ;;
  esac

  shift
done

###############################################################################
# Program Functions
###############################################################################

_dump() {
  _FILENAME=${1:-dump.sql}

  printf ">> Creating structure dump...\\n"

  _COLUMN_STATISTICS=
  if mysqldump --help | grep "\-\-column-statistics" > /dev/null; then
    _COLUMN_STATISTICS="--column-statistics=0"
  fi

  mysqldump ${_COLUMN_STATISTICS} --no-tablespaces --quick -C --hex-blob --single-transaction --no-data --host=${_HOST} --port=${_PORT} --user=${_USER} -p ${_DATABASE} | LANG=C LC_CTYPE=C LC_ALL=C sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' > ${_FILENAME}

  _IGNORED_TABLES=()

  if ((_OPTION_GDPR))
  then
    printf ">> Remove GDPR-relevant data\\n"
    _IGNORED_TABLES=(
      acl_user_role
      cart
      customer
      customer_address
      customer_recovery
      customer_tag
      customer_wishlist
      customer_wishlist_product
      elasticsearch_index_task
      import_export_log
      integration
      integration_role
      log_entry
      message_queue_stats
      newsletter_recipient
      newsletter_recipient_tag
      order
      order_address
      order_customer
      order_delivery
      order_delivery_position
      order_line_item
      order_tag
      order_transaction
      product_export
      product_review
      promotion_persona_customer
      refresh_token
      sales_channel_api_context
      state_machine_history
      user
      user_access_key
      user_config
      user_recovery
      version
      version_commit
      version_commit_data
      klarna_payment_request_log
      payone_payment_card
      payone_payment_mandate
      payone_payment_redirect
      unzer_payment_payment_device
      unzer_payment_transfer_info
      crefo_pay_transaction_refund_history
      crefo_pay_transaction_capture_history
    )
  fi

  _IGNORED_TABLES+=('enqueue')
  _IGNORED_TABLES+=('product_keyword_dictionary')
  _IGNORED_TABLES+=('product_search_keyword')

  _IGNORED_TABLES_ARGUMENTS=()
  for _TABLE in "${_IGNORED_TABLES[@]}"
  do :
     _IGNORED_TABLES_ARGUMENTS+=("--ignore-table=${_DATABASE}.${_TABLE}")
  done

  printf ">> Creating data dump...\\n"

  mysqldump ${_COLUMN_STATISTICS} --no-tablespaces --no-create-info --skip-triggers --quick -C --hex-blob --single-transaction --host=${_HOST} --port=${_PORT} --user=${_USER} -p "${_IGNORED_TABLES_ARGUMENTS[@]}" ${_DATABASE} \
    | LANG=C LC_CTYPE=C LC_ALL=C sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' \
    >> ${_FILENAME}

  printf ">> Gzipping dump...\\n"
  gzip ${_FILENAME}

  printf ">> Dump created\\n"
}

###############################################################################
# Main
###############################################################################

_main() {
  if ((_PRINT_HELP)) || [[ -z ${_DATABASE} ]]
  then
    _print_help
  else
    _dump "$@"
  fi
}

_main "$@"

