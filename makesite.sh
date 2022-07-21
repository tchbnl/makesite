#!/bin/bash
# makesite: Complete WordPress installation from the shell
# Nathan Paton <nathanpat@inmotionhosting.com>
# v0.3 Updated on 7/21/2022
#
# Releases
# * v0.1: Initial release
# * v0.2: Verbose mode added for debugging;
#         Visual overhaul
# * v0.3: (Optionally) delete created database and user if install fails
# * v1.0: Successfully brews a cup of coffee in 5 minutes

# Just in case this wasn't unset last time
if [[ $VERBOSE || $ROLLBACK ]]; then
    unset VERBOSE; unset ROLLBAK
fi

# Support for fancy text
TEXT_BLD="\e[1m"  # Bold text
TEXT_RED="\e[31m" # Red text
TEXT_YLW="\e[33m" # Orange text
TEXT_RST="\e[0m"  # Reset text

# Messages
MSG_HELP="makesite is a simple command line installer for WordPress.

USAGE: makesite [-r]
    -r --rollback       Rollback (delete) the database and user if install fails.
    -V --verbose        Enable verbose output of all commands. Noisy.
    -h --help           Show this message and exit.
    -v --version        Show version information and exit."

MSG_VERSION="makesite 0.3 (Updated on 7/21/2022)"
MSG_ERROR="Something went wrong. Check errors and attempt again or perform a manual install."
MSG_ROLLBACK="Rollback was selected. The created database and user have been deleted."

# Command options
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--rollback)
            ROLLBACK="true"
            shift
        ;;
        -V|--verbose)
            VERBOSE="true"
            shift
        ;;
        -h|--help)
            echo "$MSG_HELP"
            exit
        ;;
        -v|--version)
            echo "$MSG_VERSION"
            exit
        ;;
        -*|--*)
            echo "Unknon option $1"
            echo "$MSG_HELP"
            exit
        ;;
        *)
            echo "Unknon option $1"
            echo "$MSG_HELP"
            exit
        ;;
    esac
done

# Rollback if WP install fails
walmart()
{
    if [[ $ROLLBACK = "true" ]]; then
        # Delete the created database
        dbDeleteDb="$(uapi Mysql delete_database name="$DB_PREFIX$DB_NAME")"
        if [[ $VERBOSE = "true" ]]; then
            echo -e "\n---\n"
            echo -e "${TEXT_BLD}Command:${TEXT_RST}"
            echo -e "\u2937 uapi Mysql delete_database name=\"$DB_PREFIX$DB_NAME\"\n"
            echo -e "${TEXT_BLD}Result:${TEXT_RST}"
            echo -e "\u2937 $dbDeleteDb\n"
            echo -e "---\n"
        fi

        # Same for the user
        dbDeleteUser="$(uapi Mysql delete_user name="$DB_PREFIX$DB_USER")"
        if [[ $VERBOSE = "true" ]]; then
            echo -e "${TEXT_BLD}Command:${TEXT_RST}"
            echo -e "\u2937 uapi Mysql delete_user name=\"$DB_PREFIX$DB_USER\"\n"
            echo -e "${TEXT_BLD}Result:${TEXT_RST}"
            echo -e "\u2937 $dbDeleteUser\n"
            echo -e "---\n"
        fi

        # I miss the 90s...
        echo "$MSG_ROLLBACK"

        # Unset for next run
        unset ROLLBACK
    fi
}

# If --verbose/Paul mode is enabled
if [[ $VERBOSE = "true" ]]; then
    echo -e "${TEXT_BLD}${TEXT_YLW}Debug mode enabled.${TEXT_RST} This will create a LOT of noise."
fi

# Get the cPanel account's database prefix
dbGetPrefix="$(uapi Mysql get_restrictions)"
if [[ $VERBOSE = "true" ]]; then
    echo -e "\n---\n"
    echo -e "${TEXT_BLD}Command:${TEXT_RST}"
    echo -e "\u2937 uapi Mysql get_restrictions\n"
    echo -e "${TEXT_BLD}Result:${TEXT_RST}"
    echo -e "\u2937 $dbGetPrefix\n"
    echo -e "---\n"
fi

DB_PREFIX="$(echo "$dbGetPrefix" | grep -i "prefix:" | cut -d ":" -f 2 | xargs)"

# Get the database name and user
echo "Enter a database name and user for the site:"
read -p "$(echo -e "${TEXT_BLD}Database Name:${TEXT_RST}") $DB_PREFIX" DB_NAME
read -p "$(echo -e "${TEXT_BLD}Database User:${TEXT_RST}") $DB_PREFIX" DB_USER
echo

# Create the database
dbCreate="$(uapi Mysql create_database name="$DB_PREFIX$DB_NAME")"
if [[ $VERBOSE = "true" ]]; then
    echo -e "---\n"
    echo -e "${TEXT_BLD}Command:${TEXT_RST}"
    echo -e "\u2937 uapi Mysql create_database name=\"$DB_PREFIX$DB_NAME\"\n"
    echo -e "${TEXT_BLD}Result:${TEXT_RST}"
    echo -e "\u2937 $dbCreate\n"
    echo -e "---\n"
fi

RESPONSE="$(echo "$dbCreate" | grep -iA 1 "errors:" | xargs)"
if [[ $RESPONSE != "errors: ~"* ]]; then
    echo -e "${TEXT_BLD}${TEXT_RED}Error:${TEXT_RST} $(echo "$RESPONSE" | cut -d "-" -f 2 | xargs)"
    echo "$MSG_ERROR"
    exit
fi

# Create the database user
DB_PASS="$(openssl rand -base64 16)"
if [[ $VERBOSE = "true" ]]; then
    echo -e "${TEXT_BLD}Command:${TEXT_RST}"
    echo -e "\u2937 openssl rand -base64 16\n"
    echo -e "${TEXT_BLD}Result:${TEXT_RST}"
    echo -e "\u2937 $DB_PASS\n"
    echo -e "---\n"
fi

# The cPanel API is bugged. That's the best I can guess. For some reason, with
# the information passed to the API, even if it returns successful... won't
# work. This can mean the WordPress setup later on will fail because it can't
# connect to the database with the generated password. This was actually part
# of the inspiration for the rollback feature, to make it easier to start over
# in case the install fails.
#
# I'm looking at options to work around this:
# * Re-set the password after the user is created (nope, same issue)
# * If WordPress fails to connect to the database, re-set the password and try
#   the step again. If it still fails, concede defeat.
# * Pretend the issue doesn't exist. If so, this comment will be deleted.

dbCreateUser="$(uapi Mysql create_user name="$DB_PREFIX$DB_USER" password="$DB_PASS")"
if [[ $VERBOSE = "true" ]]; then
    echo -e "${TEXT_BLD}Command:${TEXT_RST}"
    echo -e "\u2937 uapi Mysql create_user name=\"$DB_PREFIX$DB_USER\" password=\"$DB_PASS\"\n"
    echo -e "${TEXT_BLD}Result:${TEXT_RST}"
    echo -e "\u2937 $dbCreateUser\n"
    echo -e "---\n"
fi

RESPONSE="$(echo "$dbCreateUser" | grep -iA 1 "errors:" | xargs)"
if [[ $RESPONSE != "errors: ~"* ]]; then
    echo -e "${TEXT_BLD}${TEXT_RED}Error:${TEXT_RST} $(echo "$RESPONSE" | cut -d "-" -f 2 | xargs)"
    echo "$MSG_ERROR"
    exit
fi

# Add the user to the database
dbAddUser="$(uapi Mysql set_privileges_on_database user="$DB_PREFIX$DB_USER" database="$DB_PREFIX$DB_NAME" privileges='ALL PRIVILEGES')"
if [[ $VERBOSE = "true" ]]; then
    echo -e "${TEXT_BLD}Command:${TEXT_RST}"
    echo -e "\u2937 uapi Mysql set_privileges_on_database user=\"$DB_PREFIX$DB_USER\" database=\"$DB_PREFIX$DB_NAME\" privileges='ALL PRIVILEGES'\n"
    echo -e "${TEXT_BLD}Result:${TEXT_RST}"
    echo -e "\u2937 $dbAddUser\n"
    echo -e "---\n"
fi

RESPONSE="$(echo "$dbAddUser" | grep -iA 1 "errors:" | xargs)"
if [[ $RESPONSE != "errors: ~"* ]]; then
    echo -e "${TEXT_BLD}${TEXT_RED}Error:${TEXT_RST} $(echo "$RESPONSE" | cut -d "-" -f 2 | xargs)"
    echo "$MSG_ERROR"
    exit
fi

# Give wp-cli enough memory to avoid issues
WP_CLI="php -d memory_limit=128M -d disable_functions= $(which wp)"

# Download WordPress files
wpDownload="$($WP_CLI core download 2>&1)"
if [[ $VERBOSE = "true" ]]; then
    echo -e "${TEXT_BLD}Command:${TEXT_RST}"
    echo -e "\u2937 $WP_CLI core download\n"
    echo -e "${TEXT_BLD}Result:${TEXT_RST}"
    echo -e "\u2937 $wpDownload\n"
    echo -e "---\n"
fi

RESPONSE="$(echo "$wpDownload" | grep -i "error")"
if [[ $RESPONSE != "" ]]; then
    echo -e "${TEXT_BLD}${TEXT_RED}Error:${TEXT_RST} $(echo "$RESPONSE" | cut -d ":" -f 2 | xargs)"
    echo "$MSG_ERROR"
    walmart
    exit
fi

# Generate WordPress configuration
wpConfig="$($WP_CLI config create --dbname=$DB_PREFIX$DB_NAME --dbuser=$DB_PREFIX$DB_USER --dbpass=$DB_PASS 2>&1)"
if [[ $VERBOSE = "true" ]]; then
    echo -e "${TEXT_BLD}Command:${TEXT_RST}"
    echo -e "\u2937 $WP_CLI config create --dbname=$DB_PREFIX$DB_NAME --dbuser=$DB_PREFIX$DB_USER --dbpass=$DB_PASS\n"
    echo -e "${TEXT_BLD}Result:${TEXT_RST}"
    echo -e "\u2937 $wpConfig\n"
    echo -e "---\n"
fi

RESPONSE="$(echo "$wpConfig" | grep -i "error")"
if [[ $RESPONSE != "" ]]; then
    echo -e "${TEXT_BLD}${TEXT_RED}Error:${TEXT_RST} $(echo "$RESPONSE" | cut -d ":" -f 2 | xargs)"
    echo "$MSG_ERROR"
    walmart
    exit
fi

# Get the site information
echo "Enter the site information:"
read -p "$(echo -e "${TEXT_BLD}Site URL:${TEXT_RST}") " WP_URL
read -p "$(echo -e "${TEXT_BLD}Username:${TEXT_RST}") " WP_USER
read -p "$(echo -e "${TEXT_BLD}Email:${TEXT_RST}") " WP_EMAIL
echo

# Install WordPress
WP_PASS="$(openssl rand -base64 16)"
if [[ $VERBOSE = "true" ]]; then
    echo -e "---\n"
    echo -e "${TEXT_BLD}Command:${TEXT_RST}"
    echo -e "\u2937 openssl rand -base64 16\n"
    echo -e "${TEXT_BLD}Result:${TEXT_RST}"
    echo -e "\u2937 $WP_PASS\n"
    echo -e "---\n"
fi

wpInstall="$($WP_CLI core install --url=$WP_URL --title=WordPress --admin_user=$WP_USER --admin_password=$WP_PASS --admin_email=$WP_EMAIL --skip-email 2>&1)"
if [[ $VERBOSE = "true" ]]; then
    echo -e "${TEXT_BLD}Command:${TEXT_RST}"
    echo -e "\u2937 $WP_CLI core install --url=$WP_URL --title=WordPress --admin_user=$WP_USER --admin_password=$WP_PASS --admin_email=$WP_EMAIL --skip-email\n"
    echo -e "${TEXT_BLD}Result:${TEXT_RST}"
    echo -e "\u2937 $wpInstall\n"
    echo -e "---\n"
fi

RESPONSE="$(echo "$wpInstall" | grep -i "error")"
if [[ $RESPONSE != "" ]]; then
    echo -e "${TEXT_BLD}${TEXT_RED}Error:${TEXT_RST} $(echo "$RESPONSE" | cut -d ":" -f 2 | xargs)"
    echo "$MSG_ERROR"
    walmart
    exit
fi

# We're done here
echo "WordPress has been installed. Here's the details:"
echo -e "${TEXT_BLD}* Dashboard:${TEXT_RST} $WP_URL/wp-admin/"
echo -e "${TEXT_BLD}* Username:${TEXT_RST} $WP_USER"
echo -e "${TEXT_BLD}* Password:${TEXT_RST} $WP_PASS"

# Final cleanup attempt
if [[ $VERBOSE || $ROLLBACK ]]; then
    unset VERBOSE; unset ROLLBAK
fi
