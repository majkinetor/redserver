#!/bin/bash
#
# Installs a bunch of plugins for the docker-redmine image
#
# Author: Miodrag Milic <miodrag.milic@gmail.com>
#
# Usage:
#   $ mkdir -p /opt/redmine/data/plugins
#   $ cd /opt/redmine/data/plugins
#   $ wget <linktoscript> -O - | sh

set -e
shopt -s dotglob

function i() {
    name=$(basename "$2")
    ext="${name##*.}"

    echo "||||||||||||||   $1 [$ext]   ||||||||||||||||||"

    mkdir tmp_plugin
    if [ $ext = "zip" ]; then
        wget $2 -O plugin.zip
        unzip plugin.zip -d tmp_plugin
        rm plugin.zip
    fi
    if [ $ext = "bz2" ]; then
        wget $2 -O plugin.tar.bz2
        tar -xf plugin.tar.bz2 -C tmp_plugin
        rm plugin.tar.bz2
    fi

    rm -rf $1
    mkdir -p $1
    mv tmp_plugin/*/* -t $1
    rm -rf tmp_plugin
}

i collapsed_journals               https://github.com/stgeneral/redmine-collapsed-journals/archive/master.zip
i issuefy                          https://github.com/tchx84/issuefy/archive/master.zip
i recurring_tasks                  https://github.com/nutso/redmine-plugin-recurring-tasks/archive/master.zip
i redmine_agile                    http://redminecrm.com/license_manager/15337/redmine_agile-1_3_5-light.zip
i redmine_announcements            https://github.com/buoyant/redmine_announcements/archive/master.zip
i redmine_category_tree            https://github.com/bpat1434/redmine_category_tree/archive/master.zip
i redmine_checklists               http://redminecrm.com/license_manager/14218/redmine_checklists.zip
i redmine_contacts                 http://redminecrm.com/license_manager/15889/redmine_contacts-3_4_4-light.zip
i redmine_didyoumean               https://github.com/abahgat/redmine_didyoumean/archive/master.zip
i redmine_dmsf                     https://github.com/danmunn/redmine_dmsf/archive/master.zip
i redmine_gist                     https://github.com/dergachev/redmine_gist/archive/master.zip
i redmine_inline_attach_screenshot https://bitbucket.org/StrangeWill/redmine-inline-attach-screenshot/get/tip.zip
i redmine_issue_templates          https://bitbucket.org/akiko_pusu/redmine_issue_templates/get/tip.zip
i redmine_lightbox2                https://github.com/paginagmbh/redmine_lightbox2/archive/master.zip
i redmine_logs                     https://bitbucket.org/haru_iida/redmine_logs/get/tip.zip
i redmine_people                   http://redminecrm.com/license_manager/11368/redmine_people-0_1_8.zip
i redmine_private_wiki             https://github.com/XiaoYy/redmine_private_wiki/archive/redmine-2.1.zip
i redmine_projects_accordion       https://github.com/reubenmallaby/redmine_projects_accordion/archive/master.zip
i redmine_stealth                  https://github.com/Undev/redmine_stealth/archive/master.zip
i redmine_theme_changer            https://bitbucket.org/haru_iida/redmine_theme_changer/get/tip.zip
i redmine_tweaks                   https://github.com/alexandermeindl/redmine_tweaks/archive/master.zip
i redmine_wiki_backlinks           https://github.com/bluezio/redmine_wiki_backlinks/archive/master.zip
i redmine_wiki_extensions          https://bitbucket.org/haru_iida/redmine_wiki_extensions/get/tip.zip
i redmine_work_time                https://bitbucket.org/tkusukawa/redmine_work_time/get/tip.zip
i wiking                           http://projects.andriylesyuk.com/attachments/download/564/wiking-1.0.0b.tar.bz2

# Fix some gemfiles
sed -e "/^gem 'rubyzip/ s/^/#/"         -i redmine_dmsf/Gemfile        #redmine uses rubyzip
sed -e '/^group :xapian/,/^end/ s/^/#/' -i redmine_dmsf/Gemfile        #remove xapian things, they require some local gems
sed -e '/^gem "spreadsheet"/ s/^/#/'    -i redmine_contacts/Gemfile    #issuify requires higher version
sed -e '/^group :development/,/^end/ s/^/#/' -i redmine_private_wiki/Gemfile    #issuify requires higher version


# Generate init file
cat >> init <<EOF

echo "|||| PLUGIN INIT [ `date +%Y-%m-%d` ]  |||||||||||||||||"

# ============== Recurring_tasks ===============
#
# list existing cron jobs for redmine user
set +e
crontab -u redmine -l 2>/dev/null >/tmp/cron.redmine
set -e

# add new job for recurring tasks
echo '* */4 * * * cd /home/redmine/redmine && bundle exec rake redmine:recur_tasks RAILS_ENV=production >> log/cron_rake.log 2>&1' >>/tmp/cron.redmine

# install the new jobs
crontab -u redmine /tmp/cron.redmine 2>/dev/null
rm -rf /tmp/cron.redmine
EOF

