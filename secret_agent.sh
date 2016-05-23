#!/bin/bash
# 初期化
BIT=2048
KEY_LENGTH=100
CONFIG=~/.SA-config
PRIVATE=${CONFIG}/my-private-key.pem
PUBLIC=${CONFIG}/my-public-key.pem
COPIED_PUBLIC="${HOME}/${USER}の公開鍵.pem"
USERS_PUBLIC=${CONFIG}/users
USER_SUFFIX="'s-public-key.pem"
PASSWORD=".password"


case ${1} in
  "setup")
    if [ -e ${CONFIG} ];then
      echo "すでにセットアップ済みです"
      exit
    fi
    mkdir -p ${USERS_PUBLIC}
    echo "鍵を生成しています"
    openssl genrsa -out ${PRIVATE} ${BIT}
    openssl rsa -in ${PRIVATE} -pubout -out ${PUBLIC}
    chmod 600 ${PUBLIC} ${PRIVATE}
    cp ${PUBLIC} ${COPIED_PUBLIC}
    echo "あなたの公開鍵は${COPIED_PUBLIC}にあります。"
    echo "データを送りたい相手に鍵を送ってください";;
  "add")
    ls .
    echo "公開鍵はどれですか？"
    echo -n ">>"
    read NEW_PUBLIC
    if ! [ -e ${NEW_PUBLIC} ];then
      echo "${NEW_PUBLIC}は見つからないです"
      exit
    fi
    echo "誰の公開鍵ですか?"
    echo -n ">>"
    read NEW_USER
    mv ${NEW_PUBLIC} "${USERS_PUBLIC}/${NEW_USER}${USER_SUFFIX}";;
  "encrypt")
    case $2 in
      "-in")
        FILE=$3;;
      *)
        ls .
        echo "どれを暗号化しますか?"
        echo -n ">>"
        read FILE;;
    esac
    if ! [ -e ${FILE} ];then
      echo "${FILE}は見つからないです"
      exit
    fi
    ls ${USERS_PUBLIC} | sed "s/'s-public-key.pem//g"
    echo "誰に送りますか?"
    echo -n ">>"
    read TO_USER
    TO_USER_PUBLIC=${USERS_PUBLIC}/${TO_USER}${USER_SUFFIX}
    if ! [ -e ${TO_USER_PUBLIC} ];then
      echo "${TO_USER}はいないです"
      exit
    fi
    FILE_NAME=`echo ${FILE} | sed "s/.*\///g"`
    WORK="${FILE_NAME}.encrypted"
    mkdir ${WORK}
    openssl rand -base64 ${KEY_LENGTH} -out ${CONFIG}/${PASSWORD}
    openssl rsautl -encrypt -pubin -inkey ${TO_USER_PUBLIC} -in ${CONFIG}/${PASSWORD} -out ${WORK}/${PASSWORD}
    openssl aes-256-cbc -e -in ${FILE} -out ${WORK}/${FILE_NAME} -pass file:${CONFIG}/${PASSWORD}
    tar cfz ${FILE}.tar.gz ${WORK}
    rm -rf ${CONFIG}/${PASSWORD} ${WORK}
    echo "暗号化したファイルは${FILE}.tar.gzです"
    echo "相手に送ってください";;
  "decrypt")
    case $2 in
      "-in")
        FILE=$3;;
      *)
        ls .
        echo "どれを復号化しますか"
        echo -n ">>"
        read FILE;;
    esac
    if ! [ -e ${FILE} ];then
      echo "${FILE}は見つからないです"
      exit
    fi
    tar xfz ${FILE}
    FILE=`echo ${FILE} | sed "s/\.tar\.gz$//"`
    FILE_NAME=`echo ${FILE} | sed "s/.*\///g"`
    WORK=${FILE_NAME}.encrypted
    openssl rsautl -decrypt -inkey ${PRIVATE} -in ${WORK}/${PASSWORD} -out ${WORK}/${PASSWORD}.decrypted
    openssl aes-256-cbc -d -in ${WORK}/${FILE_NAME} -out ${FILE} -pass file:${WORK}/${PASSWORD}.decrypted
    rm -rf ${WORK}
    echo "復号化したファイルは${FILE}です"
    sleep 2
    open ${FILE}
    ;;
  *)
    echo "ヘルプ:"
    echo "Ver 0.05"
    echo "setup                     自分の鍵を作ります"
    echo "add                       他人の鍵をインポートします"
    echo "encrypt                   ファイルを暗号化します"
    echo "encrypt -in [ファイルパス]  "
    echo "decrypt                   ファイルを復号化します"
    echo "decrypt -in [ファイルパス]  ";;
esac

