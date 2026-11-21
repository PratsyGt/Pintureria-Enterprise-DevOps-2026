
import json
import hashlib
import secrets

from django.core import signing

from . import pos_repository as repo


def checkout_token(uid):

    return signing.dumps(
        {
            'uid': uid,
            'key': secrets.token_hex(24)
        },
        salt='pos.checkout'
    )


def submit_sale(
    uid,
    token,
    cliente,
    detalle,
    pagos,
    cotizacion=None
):

    try:

        data = signing.loads(
            token,
            salt='pos.checkout',
            max_age=86400
        )

    except signing.BadSignature:

        raise ValueError(
            'La sesión de venta venció. '
            'Recargue la página antes de cobrar.'
        )


    if data.get('uid') != uid:

        raise ValueError(
            'La venta corresponde a otra sesión.'
        )


    payload = [
        cliente,
        json.loads(detalle),
        json.loads(pagos),
        str(cotizacion or '')
    ]


    fingerprint = hashlib.sha256(
        json.dumps(
            payload,
            sort_keys=True,
            separators=(',', ':')
        ).encode()
    ).hexdigest()


    return repo.emit_once(
        uid,
        data['key'],
        fingerprint,
        cliente,
        detalle,
        pagos,
        cotizacion
    )
