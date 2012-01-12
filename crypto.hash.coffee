{Bytes, optnew} = @crypto.util

	

commonSha1 = new Sha1
sha1 = (data) -> commonSha1.digest data

@crypto.hash = {AHash, Sha1, sha1}
