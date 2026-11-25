# @name    YouBike Stations TW
# @desc    Unofficial. Live bikes to rent and free docks at your chosen YouBike stations anywhere in Taiwan, with Chinese station names. Pick stations at patw0929.github.io/awtrix-youbike and press the knob to refresh
# @author  patw
# @version 2.0.0
# @display 52x16
# @config  st     text   "Stations 站點"           maxlen=256 group=Stations help="Paste from the station picker at https://patw0929.github.io/awtrix-youbike/ (up to 8)"
# @config  every  number "Refresh 更新間隔"         default=2 min=1 max=30 unit=min group=Stations help="How often the clock asks YouBike for new numbers"
# @config  flip   number "Seconds per station 每站秒數" default=5 min=2 max=15 unit=s group=Display help="Long names stay until they have scrolled through"
# @config  low    number "Few bikes 車少門檻"       default=3 min=1 max=20 group=Display help="The count turns orange below this, red at zero"
# @config  ebike  bool   "Show e-bikes 顯示電輔車"   default=true group=Display help="Yellow bolt with the number of YouBike 2.0E bikes"
#
# Chinese glyphs: Fusion Pixel Font 8px by TakWolf (SIL Open Font License 1.1), subset to the characters used in YouBike station names.
import json
import string

# 9 bytes per glyph: 2 bytes code point (big endian), 7 rows (MSB = left), sorted by code point
var FONT = bytes(
  "4e00000000fe0000004e01fe1010101010304e0320202ef020221e4e097c0000380000fe4e0a10101c101010fe4e0bfe1018141010104e165454fe545c407e4e180c70407c4848fe4e2d10fe9292fe10104e3010fe107c10fe104e397c445444fe448c4e3b2010fe107c10fe4e45203c44880834c24e4b107c040850609e4e580c70fe54d638d64e5d20f82828484a8e4e5f105c74d450423e4e733cd4047414fc264e7ef05eeca448f24e4e8b10fe54fc16fc304e8c007c000000fe004e92fe203c247808fe4e947c10107c2424fe4e9524fe2424fe24444e9efe28ee82ee28fe4ea410fe28c62810ee4ea510fe20542814e24ea810fe447c0810304eab10fe447c08fe104eac10fe447c1054b24ead10fe44feba10304eae10fe44fe8228ce4eba101010282844824ec1205ec04040405e4ecb1028c6282828484ed43c44c87e4848584ed52848fe4848485c4ed92848ea6a6a6a7e4ee32a48de484444424ee544544c44648c324ef0506eeaea7a68484ef2287eea6a7e48484efd3454e25c54546c4f011028d6105c50fe4f0a3e4afe4a5e48504f11287ec85c5c6a484f2f285ed25e52525e4f38287eea7e6a7e484f433e6aea7e6a6a7e4f4d287ed45454587e4f4f2844de444e445e4f50285ec84e54445e4f51285ec84e5a4a4e4f553e42de565e42464f5b547edef47e56644f5c284ed84e484e484f73285cc87e5c487e4f8610fe5454ba38d64f9d287ec85a74545a4fbf3e5cdc485848764fca327ed4665c68564fd75462c8d4625c5c4fdd3c54dc487e5c6a4fe12c5ec04c405e5e4fee286ef46a64624c50091028fe38205c9c501f547ed4fe5c545c502b2854ee407e7e6a503c287ec85c545c7e50473672e67e6a746a5049285eca7e547e4450552476e476485c5c505c287ed47e5e48585065345eee547e546e50743a6efe6e7a426a5099547ed4fe605e5650b3287edc5a7e544c50d15c7ed4ea7e626a5100547ec8fe567c5251022a5ede405e745a5104287ed47e5c726e5137366afe6c7e647651411024fa28284a8e51437c00fe28284a8e5148507c90fe282ace5149105410fe282ace514b10fe7c447c2ace51522c446c447c2ace51657010102828448251672010fe92aac28651681028fe107c10fe5169fe10fedadab692516b28282828444482516c282844921024fa516d10fe00282844825171287c2828fe00c651750c707c48fe00c65178287c6c7cfe00c6517c44fe782ef86caa51a0fe82640ef46cbe" +
  "51ac18681028d6300c51b0880a3c18ac8a9851cc881c083e94a8d651dda63a261cbe94aa51f07c547c6c7c54be51f1aefa0afa5a2af251f9eeaaaaba8282fe51fa1054547c9292fe5206282844be1424cc5211fa5656fe5252965217f24a6aaa6242865225f29afa4a7252b65229722afa2a72a2265236627aaa7a22faaa523a22fa22faaa72aa524d44fe00eaaae2a6525bfa8edeaedafa8a526ffa567606faaafa5275225aea6a4272b6527f52aa7a7afa72aa528322f23af2727ae65287223aeadab2dab652895a9aea52aa72fa528d225afaaafa52aa529b10fe1222224286529f08fe4a4a6aca1652a040fe5a5a5a5abe52a9745e7656765aea52c1f45ea656f62afa52c3246ef6962af26652c77c087c54fe22c652c964ae76762a6abe52d5e85eeaeaea4af652d9e82e54ea7eaa7652db646ef696f60a9a52ddf6a4feacfeaab652deaa44fe927c24cc52e2287cec76bc146c52e454fe56f6f62afa52f5f4aef6f6a6fada5305407eba0a7a407e53163050d25c50525e53172828ea2c68aa2e532ffed4bed49ed4fe5340fe949c80b6b6fe53411010fe1010101053430c7010fe101010534a1054107c10fe105351107c547c28fe085353101e7c447cfe105354485eea404a7e56535710fe10feaafe92535a4a7edc5c7e544c536020203c20fc84fc5361101c10fe1814105366287828fc6a38c853702eca8aea8ae808539a7e5c5c447e4898539d7e547e547e5c9c539f7e485c5c486a9853c97c1444281028c653caf8282c245448b653cb20fe203c5448b653e300fc848484fc8453e41010fe107c447c53effe04745474040c53f0101024fa007c7c53f2107c547c3010ee53f320fe207ca4243c53f8fe027a027a7a06540310deecc4c8120e540418681028c6383854081028de007c447c540910fe107c007c7c540a7c447cfe929610540cfe82ba82baaaba540d3c2458103ed21e540e0c70407e405c9c540f10fe547c3010ee541110fe82baaaba86541b7c14fe143ee23e54333ca4fc14fe10ee543c3cccd4dcf41436543e7c107828fe447c54467c447c10fe38d6547308fca8bee81c2a54773eeabeaafe0808547d1028de00eeea08548c702efa2a7aaa2e549610fedadaea0e1854c17c447c00eeaaee54c808d4eec0dc141c54e138287c7c447cc654e816e4beb2fe121654e93eeabeaafe083e54f244d85ed47c447c5510087e5c4e7c549c552d14fed4dcfe0022552e283e68be3c243c554610fe24feaade9a" +
  "5553f65a748a7c447c555f24765a7a4a74ba556114f6d4f6d43614556408feaabed43e04558008feeed4c8361c558444fe10fe54fe7c559c10fe7c28fe447c55ac38fe28d6feaaba55aeeeaafe547cfe1055b514fed4fefe2a3e55c710fe54bafe6c7c560910fe7c28fe5abe563424f6e4fedc1c2456686c6c10fe10ee6c567408fed4fed41c2256dbfeaaaaaec282fe56defe82baaaba82fe56fafe92ba92aabafe5703fe96febabaaafe5708feaafebaf6bafe570bfe8afeea8ae6fe570dfe9afeaafe8afe5712febafeaabad6fe5713febaaababac6fe5716feaabafeaabafe5718fe92febafe8afe571f10107c101010fe57304454de7654d21e5733525ada5a5ad222573e7c54d6525ae41a57404444d65454d43e574a445ee84e6aca165751487ec05c54d4265761487eea7c74e8365764487eea7e6afe08576a7e48ea487ec80857820c70fe54fe10fe5783487ec45454c83e578bfa56fe52ba10fe57a37e5cd45c54dc3e57ce447ee47c6ef42a57d44a7ec87e6afe2a57d55c54fe485cc83e57df447ec47476cc3257e0485cf45e52fe0857e4487eea7e54fe0457f7287cf454fc742657f9487ed47e40dc1c57fa287c28fe44923858007e62fe6e64d61e580254feaa387c10fe5806545ef45e74d41e58213c54fe5c6a10fe58244c4cfe4456d42e582f107cfe6cfe28ce58345c54fe505eea1658354a5cc87e50ee0e584a487eea7e6adc2e5851aefade7aca10fe5854547ec8547ed41c58578814be08ba10fe5858487eec667cea0e586d5c54dc405cdc3e5883487ed47e5cdc265885eee4ee46ec10fe58987c56fe6a54fc16589f4446dc5650d42e58a9547eee765ef41a58be2cdc6aac6a10fe58c1647e4afe6410fe58c7487ef67e5cd43e58d37e744e74ba10fe58d87c547ceeee10fe58df26fc52f45610fe58e0567cee7a6efc2e58e27e74fe7460d43e58eb1010fe1010107c58f910fe10feba28fe58fd107cfe10fe646c590ffe3838386810ee5915101e22da0408705916487858bc1a28c8591a186810ee320c70591c10fe284eda445a592228fe54feaa187059271010fe101028c65929fe107c101028c6592a10fe1028284492592b107c10fe1028c6592e107c54fe1028c65931507c90fe1028c65947107c1028fe54745949107c38fe54ba105958a4fe64ae7c10ee596e10fe74ba7c547c59731010fe246818e659765c4ceeaaca6a96597d2e22f45e6434cc5982202efa5a6a3ace59832e22f25e683ace" +
  "59d12424fe546e3ace59d32c2ef4546e24de59d438fe38d67c28f65a01047e7c546e54aa5a18445ef2beda749a5a1cbe96fcd6fe54ac5a5a5e54feb4da6c8c5a665c44feaadc7c885a9294bed4dcfe5caa5abd5e54feb4de62965ae994bef6fed67c925b2488beeafef46a9e5b507c0810fe1010305b54e8284868c84ace5b5710feba08fe10305b5820fe2c44fe48585b5d127c18fe24de085b5f7c08fe107c54fe5b6338fe3cda08fe105b6bee244864de44d65b782c54feba08fe105b8510feba10fe101e5b8710feba10fe10305b8810fe8208fe28185b8910fe927c2818e65b8b10fe927c1038d65b8f10fea2fc50a47a5b9710feba00fe54b25b9810feba283c243c5b9910fe927c7c547c5b9a10feba105c50be5b9c10feba283828fe5ba210fe9a6810ee385ba310feba003828fe5ba410feb2287410fe5bae10feaa38107c7c5bb310fe927c10fe385bb610feba30da2cda5bb910feaa5428fe385bbf10fe825ec85e5e5bc510feba7c547cc65bc610feaa60ba547c5bcc10feaa387c547c5bd310feba38fe9ab65bdf10feea44ba54b25be610feba6c3838c65be710feaa5cfe10305be910feba54fe7cba5bec10feaa7c3a3cce5bee10feaa7caa38925bf510fea6fc5274565bf610feea4cfc7cc65bfa107c10fe08fe285c01227e22fa6632c65c07a6aae43ee26aa65c0810fe3834fe28185c0b7c04ee4afe28185c0daaf652fa6632c65c0e543edc5cfe28185c0f101054529210305c11105452903418e05c1610549230fe10ee5c1a5410fe82baaaba5c3a7c447c504844825c3c7e427e505e509e5c3e7e7e4c784e788e5c407c447c407e6aba5c457e7e445e445e9e5c487e427e5c486abe5c4b7e427e547a48be5c4f7e7e547e547ea45c557e427e547e68b65c6c7e7e6a5e7a5ab65c6f16f810527e101e5c71101092929292fe5c90445e44eeeae41a5ca1feaafe92d6fe825ca9547c00fe40bc3c5cb75e525ef4fef41a5cb892fe405c487e885cd25e525ef2fefe125ce84e747ed4d6fc125cef92fe6838d638105cf04c5448f6c8fe085cf6107c7c407eaafa5cfb527e54e6dce8165cfd487e5cdceac8365d0192fe50de6ac8365d07547cfeba7c54b25d0e487e48d4fec4145d1192fe447c6e48ee5d1792feaa92d6fe825d1992fe28c67c7c545d6992fe2838feaaba5dba92fea40eee60525dd254b854ee54547c5dd692fe6c7e5a749a5ddd425252525242825dde5252f6f65252925de1aa2a54ea6a40be" +
  "5de252a47c54fe38d65de5007c10101010fe5de620fe203c48887e5de71ee8484e62c2065de8fe80fc84fc80fe5df4fc9494fc80827e5df7287c28fe74a2385e0210fe107c5454105e0320fe287eaa2a085e065cd4d4dc5454665e0c641824fe48be2a5e1d10fe24fe927c545e2548feeaaaeaea085e2b5ee8feaaeaea085e366cfe6cb6fe7c545e3854feaa38fe92105e5528fe38fe56bc345e63966af4aa7c54105e727c1010fe1010105e73fe543810fe10105e74407e907c50fe105e78107cfe28fe7c105e7b2e22d2622252f45e7c282eda6a2a5af65e84087e485c4848be5e8f087e5c447e4a985e95087e5e545e54ba5e97087e484e485e9e5e9a087e5e4a5e48b65e9c087e525e725a965ea6087e547e5448b65eab087e487e5c7e885ead087e72546e54ae5eb5087e546a5c5c865eb7087e4e7c6a5caa5eb8087e5c7e6a7eaa5ec1087e786a7a42aa5ec8087e5e4c5448b65eca087e5674766eb45ecd087e567c6e7eb45ed3087e567c6e7e945ed6087e6a546a44985eda087e7a566a5ab65edf087e706e7a7eaa5ee0087e6c567a7caa5ee3087e547e5c5ca25ef3087e745e747a965ef6c25c8654de40be5ef7c458887ec85cbe5efadc4e9c48de48be5eff4444fe4444447c5f047c107c28fe28485f0f0afe08782434c25f15f212f282f212325f18c848c888d054fa5f35de50dc90fe54da5f37c852fe9cdc4afe5f4cfe5ceabeea7eea5f4e54b854ee7c7e025f62fa5452fc5052945f691ae45224f872ac5f6d22f422745022f45f7022fc52fc70fa245f717254fa547022ac5f795c9466dc5448765f85489c48fe447e545f8b48bc4efc487e485f8c48904afe5448765f9048947ec87e486a5f915e8a54ca5e445e5f975c947ec47e544c5fa166be56de767c445fa9509e6ccc5448765faa429c5ed45e6e4e5fae54be46fe56546a5fb554be7ec67e547a5fb748be5cfe40726e5fc32010206462a43c5fc5201424aab220de5fd710fe107c00caba5fd810fe407c54caba5fe0107c547c10caba5feb48dccc7e4848765ff51028de3808c2ba601d7c547c547ccaba602148c8d47a405c5c602758dee8485c487e60467ed0dc546c487e60697c546c7c54caba606d287c28fe4420aa606f107c447c7ccaba608554e2fe627e5466609f5cc8fc547e545c60a0265ad45a00caba60c548dcc87e545c5460dc54fed47e5c545c60df54def45e54545e60e010fe547c74caba60f32efa6eba2ec0ba610f107c28fe38caba" +
  "611bfe54feaa6418e6611f047e74b200caba614844fe244824caba614b54f6507456c8ba61625cd4fe7e544876616744ee44fe3ccaba6176087e547e7a4cb66182fe3838feee10ee61a9f44efa6e00caba61b210fe927c38caba61c9087e566c6e52ae61f748feda7e48745a620054b854ee54caba620e0afe0848ea449a6210047e44745654aa62111a68fe28fa246a622a2a78fe287ad47a6230dedc767476fc2262322634eef4d6a4fa62360e707c447c4080623ffe447c487e54ac6240f20c785e7a4a926247fe7c407e6a5eaa624d08fe080c18e818625844d8487ec84ace627648dc487ec854e2627954d45e54d45cf6627f3808d27c54ba10628048fe487cd448f662955cd4665cd448f662b150de7a4ada50de62b542dc545ed452de62bd48fe6a7eea6afe62c948fe5454d458fe62cd48fe527ed252de62d44afe486aca54ca62d650de745ef650de62db5eea5266de52de62f154fe5454fe40e2630752dc525ec05ede631648fe765cc852ce632f5ed05650de74da63504cec407ed25ed2637744de465cc654ee639254f65476d476d463a27ee25466fe5cea63a548fe547ed44cf263a854de745ed454de63d04cec5e44d654ee63da5cd47e50de6ad663ee7eea7e5cdc7ec863f446f86a5eca54ea645848fe547eea76fe64ab60fe547ed47eea64ad7ed47e5cea5cdc64cd5cd47e6afe5cea64fa7efe5466f074f665246afc567cfe54ee652c74e6765cdc5ce6652f10fe10782810ee653628aebaaaaae43a653ff4262abaaab4ca654548ee5aeaaae41a654f84f66a7aaaf42a655124f62aba6ab46a6557e8aefaaaea04aa655924762afa5ab42a656354f65afa5a745a656624f65a7a3ae42a656c54f65a7a9a543a657426fa74aafe5cfe65782476da6afa54ea658710fe28281028c6658c5ae43ea4545cba6597482848280ef8086599a454e454c6fc4465ace458f0fe54e44465af52fc587efa0a9265b022fc582efa72aa65b7aad4acfeaed6fa65b910fe203c24448c65c110fe24fea23cc465c548ee5468ba2c6a65cb48ee506ea62c7665cc48ee506cae346e65cf48ee586cbe246a65d748ee5c6cbe207265e5fc8484fc8484fc65e97c447c447cfe1065ed4efa5e5a5e509e65f17c447cfe10fe1065fa1ee4a4eea4e41e66027c447c4e8aea0866067c447c486e48ee66077c447c28fe2848660c7c44fe82fe82fe660eeeaaeeaaee1226660f0c707c48e67c7c66137c447c207eaa56661f7c447e50bc10fe" +
  "662008fcb4fea8e8366625107c38fe44ba38662d1eeab2e6bef21e664208fca8fea4fe146649fe486cfe7c447c66683c247e5c7e68b6666e44fe6c28fe447c666f7c44fe447c54b2667404eea4feaaee0a66767c44feaaeeaaee66777c7cd624fe447c667a407eaa5efc447c66891ef6beecacfe0466a8feacecd67c44fe66ab2ef86ef4247c7c66c908fcbef6bed42666e614fea8feb6ec1a66f228feaafeaaaafe66f4fe547c547c30ce66f8107c16fc10fe7c66f928fefeaafe447c66fe2844fe547c447c66ff44ee44aa7c447c67031028fe547c447c67083e223e223e4286670920fe207ca43c24670b7e5a7e5a7e5ab6670d7e52705e7a54ba67174eeaaeea8eaad6671b2efa4e72fe10fe671dee4aeeaa4eea56671f5efa5e7afe0a96672810fe1038549210672c10fe103854ba106731507c90fe1038d6673428f8287c6aa828674922f4227460a22c674e10fe3cda08fe10674f10fe38d67c447c675044fe44c6cc744c675124fe24746ca42c675e5ee242fed0525e676d48fe40dcd45466677110fe547c5438d6677e54d462c8c8547a677f5ed05edada645a678b44fe48eeca4a56679724fe246c76a424679c7c547c54fe38d667b640fe5abefe38d667cf48fe52fed2525e67d154fe54dcd4545c67da48fe6afeea6a7e67e510fe38d67c7cfe67f356e676f6f6546467f424b6a4f6fe38d667f55eda5afeda5a526817fe547c10fe38d6682148fe54e2d44876683848fe50ead44c72683c4cd448d4e25c5c684248dc48fedc487e684354f654f6d45466684810feaa74fe38d6684c101e7c44fe38d668505ef25ef2de5e5268513808e622dc38d6688550de4cfed45e44689348fe54fec87e4868a75cc87cd4fe545c68af54fe4afee85e6a68b044fe54fcd6544a68c948dc54dcfe6a4868d248dc7ed4ea5c4868d710fe5438d638d668df48fe5cdcc85c6a68e74afe44eade445a68ee107c3854fe6cb668f248fe4cdcfe547a68f57eea7ec8fe5c6a690548fe48d4fe4454690d44de44d6d6505e69307ed65cded67c44694a5cd47ed0de6a5669537eea7efeea6e5a696048fe48f6ea7e6a696848ce5cd4dc5c62696daafe287cfe38d669755ee84cf6d6445e69797cd65ae6dc5c7e699456fe6cfee66c74699548fe76c8d46e4c69aeaa44fe927c38d669cb54fe54fedc7e5469fa48fe6eecfa6c5a6a0252bc6abcfe38d66a1348dc76dcfe547a6a197edc5cc0fe486a6a1f48fe54fedc7e486a2154fe5cd4fe4876" +
  "6a386afe54fedc48766a3952fe52faee527a6a3a54fe5cfedc7e486a4b5cfe54eafe626a6a5f52e452fcd6546a6a6b54fe54fedc5c626a946adc76dcfe6a7e6a9c48d47eeafe545c6aa248d47eeafe546a6aa854fe48feee446a6ab348fe6af4dc5c626ac37eec7eecec727e6afb76f66ad0fe547a6b096afe54feda7c4a6b0a54fe76d4de745e6b21901e2a088894a26b2314664a7454549a6b3d48aef644e464da6b4ce82eb6e424a47a6b50f4b6ba84dcdcfa6b6154f6da6474e47a6b6210105c505050fe6b63fe10105c5050fe6b642828baaca8bace6b65105c50fe5498706b666a08fe145c52fa6b72105c50fe7654aa6b777e547e544654be6b784cc6acfe76ceea6b8af85c68be685caa6b98ea5e64aa7e449a6bafe87e6ab47c5ca26bb52e4a604e6ac45a6bbc4efa609efa64ba6bbf7e4a706e7a44aa6bc52efa50fe6ab46a6bcd3c3424fe547e0c6bd448487a4c487ace6bdb0c701ef01ef01e6c0f0c70507e4844e26c117c447c507e48e66c1b407eb87c8c34526c23407eb87cac74aa6c341012f4385492306c38300032d45894326c40be0888088888986c50880e922a8488b06c558808aa2aaaaabe6c5f803e88088888be6c6084149e3694929e6c619c00be109e82866c74883e880c8a88886c7da03ed83c8484826c828438a03ea4a4c46c90883e881c9caa886c99881c9a288a84986c9b883e883eaaaa886cb1883ea21498929e6cb3be02ba2aba82866cb9883eaa3eaaaabe6cbb8808943a809c9c6cbf941494229c949c6cc9107c447cda54b26cd5881c883e8894ba6cd7be36b636a2a2be6ce2883eaa3cb4c8b66ce5be22be28aea8ce6cf0107c38ee5438d66cf39800986aacca986d0b943e881c88be886d1b8c148814a29c9c6d1ebe22ba22babaa66d25883c8e3c88be886d2a943e9414be80a26d32aa2afe7eaaaaca6d3b8418be089c949c6d3e8438a638b6b4d26d41883e943a989aaa6d668a3e883eaabeaa6d69981ca83e809c9c6d6e8e34801c84be886d7494228814a29c9c6d77a03e9c7eb4be8c6d789c049c3eb688b66d88aa08be22bea2a66db5be18aa3ebeaabe6dbc883e941c88aa986de1aa14a208aa94a26de89c2a9c0cbe8c986df1be229426be9caa6df5aa2abe22beaaca6dfa8a3e841abe849a6dfb8418be14a288aa6e05881c883e949c946e20be3ca43efe38d66e21883eac3eaaa4da6e2dbe2abe3e949c946e2f943e947eaad09c6e349c149c1eb29a866e38a87eae32d49eb4" +
  "6e56ae7aae7adefa8a6e6f9c14be109eaa966e73883e8836aabeaa6e76881c941cba9caa6e90be24ae2ea4b6cc6e96941eb41e90fe106e9c8e36a63a9c9c9c6e9d943e943e9cbe946eaa9c2a9008be88b66eabbc2cb43c80bcfe6ed19c14be229c9c946eecbe1e941e9ea88e6eef943e942abeaa886ef7880ebc36aab6be6eff943e943ebebeaa6f018c349e1a9e80aa6f14883ea21caa9ca26f22947eaa3efe88b66f2fbe2abe10be88aa6f33883e943e9cbe886f3e943e9c08ba9caa6f54963e963abe88aa6f64f676de4adecade6f6dbe1c801c94be886f6ebe1abe3a9eba926f84ba14a21c5488be6fa4be3e883e94be886fb3881e9e1abe88b66fc3943ebe00beb4da6fd5be3e9224b680aa6fdf883e942a949ca46ff1883eaa349c9ca2700b883eaa14be9eac7011be3e943eaa9caa701ab41ab03e96ba92701b887ea03eb4acd67027967cae7aaebcae7028ac74fe7aaef0aa703eb636aa3eaabeaa70639a2c9a3e9c9e82706b101054581028c6707d4a944a105428c670ba28781c247e825670c8f24a6aa24600aa70cf107c447c7e02aa70d8547ed4d47e40a2711a24fe6cb65428c6712180fe54fe54feaa7136745eb424ca00aa7149487edcdc485caa71595e4cfede5e649e7164547ed4dc7e5caa71655c64dcdc7e48b67167feaaf2aeee00aa7199f6a6d6a4f600aa71b1286cf46cb600aa71c87a54e2dc5448be71d2485cfef67e54a671d528fede54de00aa71dfaa44feba107c7c72104446dcd6506c9e722c106676747670ae7235fe547e7e6652f6723628c628281028c6723828c638d67c423e723a28c638c674f614723d10fe54385428c6723efe54feb6dab6da724748487e407c4484724ca8befa9eecbea4725b507c9010fe101072616474ae34e4242e7269d0deee4ed66a56726f6474ae34ee2a2e7279c8dcc87ec47e54727d10fe64feba7c1072816afa6ab23cfe1072c0aaa8fe28e874a27334ac64fe68fe64ba7344b65ca67ca43cda7345ae74be6ebe34c47378f6f47e74f4547a738410fe20681024fa7389fe10107c1014fe738bfe10107c1010fe7396e84e52e444ea1273a5ee4a4eea4eea1673a9dc407ed454d42673abd05e74d454c83673cde8546ac46ac41873e0d85c68fe48dc2a73ede64c6cee4cd42e7403ca7e48ea5cea187405e45e72de7ad41a7406fe6a7eea7ec83e7409c87e54fa58da2a745eea7e40fe50fe2a7460ce7666fa5cdc1c7464ec5448de64d61e746afe687ce87ec22a" +
  "7470d07e6afe6adc2e7489e45e4cec7ee43e749fdc547ed45cc82a74b0fe6a7ed45cea0874bdfe54feb6da7cfe74caec564eee5ae41a74e6fe203828584aee74f7901e2a94fe24f6750cfeb8bc8cdcdcfa751844fe447c44447c751f507e90107c10fe7521ccee54e44ee41e752210fe387e5c48be75287e527e527e52967530fe9292fe9292fe753110fe92fe9292fe7532fe92fe92fe101075377c547c54fe22c6753af0bef4b4b4f40c753bfe10bababa82fe754c7c547c547caa4875592ec696ea7c547c756afe54fe38d67c7c757654feaa387c547c7586fe2c6c5eec6cde758fe83e547ad8daea75be087ed05cfe48b675c5087edc7eea76a2764c087edc76f66abe767b74aa44ba2810fe767c74aa44ae4a246a767d20fc84fc8484fc767efe107c447c447c7687107c447cfe10fe76934ceeb4fea0ee0e76ae087e4a7c5448b676ca44fe44827c54fe76db047e64aa7c54fe76dfeeaaee127c54fe76e3e8ced0e67c54fe76e46e6af4aa7c54fe76e7080e784e5c5cbe76eefc84fc84fc84fc76f410fe10bca4bcfe76f82efa2e7a6eaa2e77011054923ce43c3c77097e4a7e525e529e771f10fe3838fe00c67737549228fe44ba38773efeaafe1054ba1077632e3af4aa7c447c7766e8bcfeb4e6a8fe77e5407eaa7a2a5a8e77ed9ee05ef25e6c9e77f3fe20207ca4243c77fde84e528a6468107802e85c5a886a64187814fe4a4a9e6a6a127832e84e56826e680e7850fe525e927e7e127887e45e56846e6c167893f45e549e74741e78a7e44eea4efe64bc78a9fe485e927e601278bcfe545e947e621678c1ea5e4a946a741e78d06e6af4aafe64bc78d8ec5a549e6c761e78faea5e4a9e6c6c127901ea4e5c8c6e6016790eea5e4a946e6c167926e45e569e76600a792bda6c5aac7e5c2a793a7c00fe10549230793e44e42e44e4445e795048fe284efa4a4e79565cf43c54fc547e795e48fe2a7eea7e487960de02da42dada4679654afe244ee45e44797fce14fe48eadc6a798f5eec2c40fe565e79a7c83edc54fed45c79aaf636dc5cdcfe4879aeea1efe5ef2cc5e79be0c70fe1038d61079c038fe38d6782cc479c17424f42478aa2e79cbc848ea6cc8d46279d1e454e454c6fc4479dfdc54dc54dcd47e79fbec54e856eac4587a05d462fe62fed4667a0bdc54fe48dcc87e7a1af45ef45ef4d45e7a20fe6afe6af6fe627a2ec458fe5cdcc87e7a3bdc6ac056e2f67e7a3dca7ed86ed0de5e7a402efa20feaa74aa" +
  "7a4dc85cc87edcdc627a57c87edc5ac0f26e7a7610feaa4cf82ace7a7a10feaa4c3810fe7a9f10feb67c7c6abe7acb10fe44242828fe7ad948e8aea85ef21e7ae0107c28fe44fe107ae5107c28fe7c10fe7aef6afea0be50fe2a7af9486eb42424242c7aff486eb47c10fe107b11486eb410fe10ee7b28486eb4fe54ba107b2c486eb47c503ed27b46486eb47e14fe107b49486eb418fe28187b4f486eb446dc445a7b67486eb438383ace7b8f486eb854fe1c307ba1486eb4feb23c3c7bb4486eb47e4674ba7bc0486eb4eeea9ae87bc4486eb4fe6af82e7bc9486eb44cee38d67bd9486ebc28feaaba7be4486ebc507e02aa7c21486eb4eeeebaba7c43486eb46e6038fe7c6c486efc5ceebcee7c735410fe1038d6107c89b454e25cd4d46c7cb5107c7c74fe041c7cbea85cc87ed4dc547cd5947edc48fec06a7cd6a47eec66fcea4e7ce7bc54fe5cdcc87e7cfb7c106014fa10927d005e8242be50f25e7d04488e52aa46e2467d05409e44a444e45e7d0b48be549448d4627d0d48be6aaa76e2667d107c9454be54d47e7d17489c5aa84ae4587d1a7c9456925ae45a7d1b5494629c54d46c7d22107c10feaa30927d2b24b6a4f67a10927d305e9656be56f65e7d395e8a52a65ef25e7d614c94489462dc5c7d7148be54ba54d4667d8f5caa40887ed47a7d935e8a54aa5ee45e7d9c48be6e807ec86a7da04e947e88ea1caa7dad549e54be54f45e7db27ea276fe6aee627dda489c549c7adc6a7def489e4abe54fe447df448be5c9c48dc6a7dfb7c9666be56fc4a7e236ee4e884fe24b67e3d489e5ebe40f26e7e61489c4eb4e236967e697eb654b676d45e7e7c6ab46abe6af47e7e7d48be6ab45cdc627e966e947e947ed47a7e9c74a6769c5cdc667efd44be6e84d614ee7f5ffeaafe10fe447c7f69feaafe1c78fe107f6efeaafe24bca4fe7f72feaafe38fe34dc7f75feaafe507e02aa7f85feaafe945ef45e7f8e28fe7c10fe28c67f9aa854ee40fe4a887fa4fa5ef45e64fe747fa944fe10fe2afc2a7fbdfe125a1236da367fc128c620fe5a36da7fd2fe5a36da207c7c7fd4be4ade6ade6a8a7fe0fe5a36fe54fe107fe128ee28fe5ab65a7ff0e854e2be4ade6a80002eb62ef46e7c8e8001127c18fe3cd01e8003127c18fe30de028010fa46faaeaeaaaa801554fe54d47ed46480186ec05ee444ea5e8033fe243c3c24fe048056fe6afe107c10fe805afe6af42a5438d6806fea746a747eee348070e87e7e7e60fa36" +
  "80722efa648a3cfe048077f67c6e7c66f43a807de47e6efe60fa368085107c3eec426eaa808910fe92aa92aa868096a468fc84fc848c809ae4a4eea4e4a4be80a1eeaae0aeeaa4ba80b210fe24fa447c4480cee4a4eabee0aeae80dee8aef6a2eea8ae80e14eea4eeaaeea1680f8e8aef6aaf6bea280fd2456f4765674568154e4befaa0eea4be8173eeb6eeb6feb4bc81e5f4a4f494f4a4fa81e8f4a6fe96f0aefe81ea20fc84f4bc84fc81f3fe2874107c10fe81f4f4265afa6a34ca81fa10fe38feaa74fe81fbe85eac7eea5cea820766baceaafe00c6820846baeebafe00c6820a28fe7ca83e6c7c820d1028fe10fe447c82164abe48fe6abeea821844be52ec4eaaee821e80fe54fe54be44822a48fea0bcf4b4a682394aeaaab0eeaaae823a5ef6beb6fea4a4824b4ce4bea8fcbcbe826f107c447c5448e6827238c87c547c423e827e28fe28002810ee828b28fe287c10fe30828e28fe2878407e02829928fe107cfe10ee829d28fe107c0850be82b128fe284acc4a4e82b328fe10fe203cc482b828fe287cfe24fa82d128fe287eda28ce82d328fe1028fe121082d728fe287c7c547c82e528fe20fe40bc3c82e628fe28fe107c7c82f128fe2854fe10ee82f328fe186818e610830228fe287e4a449a830428fe2840fe5abe830528fe7c08fe52b0833528fe92ba92aafe833628fe1028fe1092834928fe7c447cfe10837728fe285ec25a5a838a28fe20a4fe64ae839228fe2838007c7c839828fe107c28fe1083bf28fe20faaa72aa83c128fe38fe547c4483d328fe7c54fe38d683dc28fe5408fe38d683ef28fe54fe54fe1083f828fe44ea4460a6840a28fe5454ba38d6840d28febe1caa3e88842328feba105c50be842c28fe547cfe9ab6843d28fe8c3488369c844628fe54dc7e5c6a846b28fe4eea4eaaf6846c28fe6ca84efe48847328fe7c546e54aa849c28fe66ee44ee4484c128fe38fe5438d684ec28fe4c34da48be84ee28fe4c0cde44be851728fe547e5c40aa852128fe6a44ba54b2852328fea6ea3eeaa6852528fe7c6c7ccaba852c28fee43e50deea854928fe7ca83e00aa856d28fe3cee426eaa858728fe5e867ed46a85aa28fe5c28fe7aa285cd28fe684e6038fe85cf28fe04befc74da85dd28fe2c76fe24fa85e428fe2af4aafcaa85e528fe7aacfe38d685fb28fe942abe1caa860628fe0c784e5cbe860728fe6cbe6c16a4862d28feee92febad6864e080e784e4054a68655080e785e6c54ae" +
  "865b080e784e7454be865fc8ce38eea06cd6867940eea4e44464de86b55ee2bef65e62c686cbfe1a50be3814fa87065ef2bef25e6cd687605eecace05e76de877456fed6fe6e7eca87766afeaee07e5cea878df46e6afe94f6be87a2aa44feba3814fa87ba7eeabed07e48ea87e07ed4fedc6a5cdc87f2107c7cfa6c6cda87f96ea66a7ebc14fa8840207c54545454fe884c5c807ec444444c885356b856fa7a5256885756b856fa527a4688595e885eda425a5a885b56b85eea527a5688615ea856fa7a526a886310fe102aec24728868107c10fc2ae432886b42ec224ce0624c888b2a5ec452fe68b688cf10fe547cfe68b688d554e22854e26c4c88dc4afe285efa7e5a88e15ef63e56fe645e88fd627aaa72fe68b6891210fe54dc2ae432897ffe28feaace82fe898b7c447c447c2ace89965ef23e52fe4c5689aa2efa5e2afe74aa89ba2c54feba283ace89bde8ceee38383ace89c05efade6a7eec7689d238c87e527e428689e36ea67a7e745eb489f87eb66e726e6eba8a0038fe0038007c7c8a0844e41ec404e4e48a0abcd41cb414d4e68a1352da1ada1ad2e28a185ee202de10d2de8a2d5cd426dc14c8f68a3150dc28c83ec8c88a3a48d42ac40ac4d88a545eea12c61ed2de8a6058c018ba1cead88a664ac83ec43cd4fa8a7144d83ec81cd4dc8a9e5cc83cd43ed4dc8aa044fe24bc2ef4ea8aa446d61cc41ec0d28aaa54e23ea23ed4e68abc44de12cc0cccde8abfbeea3eaa36fee28ac7aad422c82ad4e28acb48dc08be14dcd48b6656fa749a30fe388b7094fe08be16fcd28b7794fe1cde14c8f68b7d2c545cfe44ba388b8a54b8547ea418e68b9348fe36dc3ef4da8c3728441028c638388c46fe007c447c28fe8c50547c7cfe4438fe8c6138c83c3cda2cda8c6cea5ca87eb42ece8c822ec66aa06eaa4e8c932ade6abe7eb65e8c9d7c447c447c00c68c9e101e7c447c7cc68ca1e4bee4a6ec14ac8ca27c10fe7c447cc68ca8284ec84e3c3cc68cab7cd67c7c447cc68cb30afe68086464928cb4107c54fe447cc68cb7feaafe7c447cc68cbf2ec6ea7c447cc68cc040fe5abe243cc68cc7901e2a947c7cc68cd310feba547838c68cde54feaa7c447cc68ce2eecae40a7c7cc68ce6f6c4fed4dc34ba8cea24486ebc243cc68cf42cf47e7a2e70aa8cfcd4fed4fedc3e948cfd10feaa7cc67cc68d64107c10fe28aa588d852ef62af06e6a9e8d8a44fe54f654dabe8db37c447c105c50be8ddffeb2de72def4da" +
  "8de1e8bed476f6d4ec8de8e4beec5aecc2e68defe6aae44af0ceee8e10eabee44afec4ea8e5fe8bcc87edcdce28eab103c243efc146c8eca10fe547c54fe108eccd07cd4d454d4668ecdfe92fe7c54fe108edfe84ef6e444e45a8f09287a28fe66f42a8f14ca7ec8fe6afe6a8f15fe4af4ea5ee45e8f1cea54eafe5ef65e8f1d3eb63eec6c7e848f2ae854eee05efe568f46c87eecfe7ee4768f49c87edcda7ed44c8f9b107c28fe107c108fa654feba5cfe5cac8fb07e405c407e68b68fb2287c7c007e68b68fce902e2aea7a48be8fd1845810de5464be8fd49e501eda546abe8fea883eaa3eea7ebe8ff08a3e08ea6a48be8ff4be22be36fe62be8ffd885e1ed05e52be9010be501aec5a68be901abe043eea7e6abe901f887e2afe5c6abe9020981c28fe545cbe90228c341ac87e48be9023883e1cdc7e48be9032941e34de545ebe9035881cbe16e85ebe90388c341eda4c56be904a943e16da6e54be904bbe2a1cdc7e48be904e8e4a0ade525abe9053943e08d45c54be9054881c3ed47e48be9060881c3ed45c6abe9069883e14fe6a76be9078b61224f65c62be907a883e2afe5c62be907c883e14fe546abe9084be3e14dc6a48be908a88149c3eee54be90917848fc94fc827e90a62efa2cfa2afc4890b816e6a4f6a694ec90ce4eeaacea8aace890e1f656fc5666f47490e82efa5cfa0a6c6890f57e2afc6afa2cf890fd2e7a2cfa4abc38910956be6cbee66cb49127ee568c76563cc4912d56fedc8efe24dc9130ae76ac06d67c94914dee42e2eea8eaee9152be14be36a2bebe9192ee4aeef4aee4fe91abfecaf4aafe6c7c91c70ef05408fe38d691cc7c547c547c10fe91cd38fe547c5438fe91cefeb2f4bef624fc91cf7c44fe547c10fe91d11028fe10fe54fe92805eb2fe52fe74da92855eb2fe52fe7ed292984eaaf448fe6ace92b754aad45cd45cd492c15eb2fe40fe72de92d048beea5ee852fe92d24cb4c876c87ec892fc7ea2f66af67ee2932648bcd45cfe6ac8932f54bed47edc54dc938c54bedc4efc5cea938fbe109e2afe54fe93ae44beec4cfe60d293e148bed47edc5ce6943556bcfe6cfe54fa944448bcfe48fe74cc945154b6f056e06cde947c7eaafe64d67cd6947d68bed46adc5ce2947e54b854ee3854fe95773c203820fe28769580eeaaee82828286958beeee82feaafeaa9592eeaafeaabaaada9593eeaafeaabaaaba95a3eeee9aaa92eeba95b1eeeeaafeaa9aee95caeeeedabeca96de" +
  "95dceeeea6cafeaeca9632e4bec8aeaaca96963ffea2deb6bec2869640e4bed2a8aec88e9642c4de96deda94aa9644eab6d2bab2d2969650feb2deb2bed49a965dc8fe9cdcea88b69662c8feaec0fe94a69670c8d4bac8fe94ba9673c8fe9cdcc89caa9675c8dc88fed4a8969676d0deaadecaaebe9678c8dcbed4e688be967ddcd4bed0deaa969686ccd488f6dc88be968ad4fe90eadcaa98968be8bed4aebcdc94968dc8dc94dcfe88be9698d4e29cd4e29cbe969bdeea94e2dc88aa96a7ecd2aeccf6acbe96c17e546e7c6e6cae96c42afe2c4e5cac7e96c5eaaebcee6cac6e96c6287ca83cfe38d696cd10fe549ef4549e96d5faaefcaedcfc8e96d9547eec7e2810ee96dc2afe5caefc7cae96e8fe10fe92b692b696ea38feb6007c047c96f238feb600fe24fa96f638feb628fe121096f738feb6007c547c96fb38feb67c547c0e970438feb67caa3828970738feb67c7e68b6971638feb624fe6cb6971e38feb6ee8ae48a972738feb66cfa66aa973238feb6eaa45aee974838feb6fefe54fe9752107c10fe447c44975644eea4be4aee0a975c5cea5cecfeeca8975e28ee28ee28ee489760507cfe447cee489762fe10feaabaaafe976928fe287c54fe109776bef6f65ef0f25e978ba4eee45eeee45e97f3107c28fe7c447c97ff76b666bc28fe389802fe485e525ec01298065e747e7a7e509a9810ee244eea6e40d298132ef42eaafe203a98185ea4ee0aee6052982dee04eeaa4ee012984c6e64fe2e706a9e9858fea4fefaaef0aa9867fe547666f6607a98a87c547c7c545cb698dbfc54d27cd6549298df1028d63034287698ef5eb05edada94ea98f248ae56e4e484ea990a44fe10fe7ab43a99102e74da387caa34992844be52ecee8aee995248bcfef6bed4a6999644fe107c7c447c99990c70fe38d67c7c99a5782efc76aa747a99a82efa649a38ee3899ac7e507c507e02aa99c1eac4eac0ea24ba99d540fe5aae3e02aa99dde4def2c8ee28ae9a30f6a4feaceea2b69a57e8d4feeafe34aa9a5bfedee4deea3ea49aa87c4cfec67c444c9ad46a7efebe726c7e9ad810fe2838feaaba9b2eeec69aeababa9e9b3154ee7cfaf442749b42e81efa5ebeec169b4d5efaf6fa7e72be9b5a38c87c547c00aa9b6f38c87c7caa7c7c9bd364ae6a6e7a06aa9be47ea27e647624b69be864be6a6e6416ac9c32266af46afc7caa9ce5107c7c407e02aa9cf37c5474747c4cae9cf408dcdcd0de022a9cf60afe147a7e02aa" +
  "9d28e8fcfcf05e42569d3b847eae28bee2969d5d34defe585ef25a9d6cf4befeb8feb2ba9dafaa44feba3e02aa9db424feae78ee62769de5448844aafe02aa9df9087e6c6e5e42aa9dfaecb45eec3e02aa9e7de8cedeee7c54fe9e7f087e547c7664b69e97eeaa7e547e64b69e9f56ecb6e0daee929ea510fe54aa5c28d69eb52ef46ebe5eae5e9ebb087e547e547e949ec328fe38fe547cc69ece68fe6ab628fe549ed17c547c107c00aa9ed8eae8fe48e814a29edee8e8ee48fe12be9f0e38babaee286eaa9f1344ee44aeca64da9f3b1038287c54fe489f4a10fe6cba447c849f4b10fe6cba447c949f6124baeed0bed6f49f8d26fc56fa5674569f9c38c87cee6eec3eff0820408080804020ff0980402020204080")

var BIKE = ["........##.", "..##....#..", "...#####.#.", ".##.#..###.",
            "#..##.##..#", "#..#...#..#", ".##.....##."]
var BOX = [0x7E, 0x42, 0x42, 0x42, 0x42, 0x7E, 0]
var YB = 0xFFEF00       # YouBike yellow
var ORANGE = 0xFF8A00
var RED = 0xFF3030
var GRAY = 0x8A8A8A
var BLUE = 0x4A90E2
var TRACK = 0x262626
var LIVE_URL = "https://apis.youbike.com.tw/tw2/parkingInfo"

class YouBikeTW
  var ids, names, lays, rows, per, every, low, ebike, ink, bike
  var busy, busy_at, next_at, ok_at, fail, err, cur, since, poke
  var msgs

  def init()
    self.per = int(store.get("flip", 5)) * 1000
    if self.per < 2000 self.per = 2000 end
    self.every = int(store.get("every", 2)) * 60000
    if self.every < 60000 self.every = 60000 end
    self.low = int(store.get("low", 3))
    var e = store.get("ebike")
    self.ebike = e == nil ? true : e
    self.ink = settings.get("textColor")
    if self.ink == nil || self.ink == 0 self.ink = 0xFFFFFF end
    self.bike = []
    for r:BIKE
      var m = []
      for x:0..size(r) - 1
        if r[x] == "#" m.push(x) end
      end
      self.bike.push(m)
    end
    self.msgs = {}
    self.parse(store.get("st", ""))
    self.rows = {}
    self.busy = false
    self.busy_at = 0
    self.ok_at = 0
    self.fail = 0
    self.err = nil
    self.cur = 0
    self.since = now_ms()
    self.poke = 0
    self.next_at = 0          # fetch right away (a settings change or data push reloads the app)
  end

  # ---------- settings ----------

  def trim(s)
    var a = 0
    var b = size(s)
    while a < b && (s[a] == " " || s[a] == "\t") a += 1 end
    while b > a && (s[b - 1] == " " || s[b - 1] == "\t") b -= 1 end
    return a < b ? s[a .. b - 1] : ""
  end

  # "500101001:科技大樓, 500101002" (half or full width , and :) -> ids + names
  def parse(s)
    self.ids = []
    self.names = []
    self.lays = []
    if s == nil return end
    for chunk:string.split(str(s), ",")
      for part:string.split(chunk, "，")
        var p = self.trim(part)
        if size(p) == 0 || size(self.ids) >= 8 continue end
        var c = string.find(p, ":")
        var cl = 1
        if c < 0
          c = string.find(p, "：")
          cl = 3
        end
        var id = c > 0 ? self.trim(p[0 .. c - 1]) : (c == 0 ? "" : p)
        var nm = c >= 0 && c + cl < size(p) ? self.trim(p[c + cl ..]) : ""
        if size(id) == 0 continue end
        self.ids.push(id)
        self.names.push(nm)
        self.lays.push(nil)
      end
    end
  end

  # ---------- text ----------

  def utf8(s)
    var out = []
    var i = 0
    var n = size(s)
    while i < n
      var c = string.byte(s[i])
      if c < 0x80
        out.push(c)
        i += 1
      elif c >= 0xE0 && c < 0xF0 && i + 2 < n
        out.push(((c & 0x0F) << 12) | ((string.byte(s[i + 1]) & 0x3F) << 6) | (string.byte(s[i + 2]) & 0x3F))
        i += 3
      elif c >= 0xC0 && c < 0xE0 && i + 1 < n
        out.push(((c & 0x1F) << 6) | (string.byte(s[i + 1]) & 0x3F))
        i += 2
      elif c >= 0xF0
        out.push(0x25A1)
        i += 4
      else
        i += 1
      end
    end
    return out
  end

  def glyph(cp)
    var f = FONT
    var lo = 0
    var hi = size(f) / 9 - 1
    while lo <= hi
      var mid = (lo + hi) / 2
      var o = mid * 9
      var c = (f[o] << 8) | f[o + 1]
      if c == cp
        return [f[o + 2], f[o + 3], f[o + 4], f[o + 5], f[o + 6], f[o + 7], f[o + 8]]
      elif c < cp
        lo = mid + 1
      else
        hi = mid - 1
      end
    end
    return nil
  end

  # -> [width, [[x, glyph rows | ascii string], ...]]; call only from draw() (measures with the small font)
  def layout(s)
    font("small")
    var items = []
    var run = ""
    var x = 0
    for cp:self.utf8(s)
      if cp < 0x80
        run += string.char(cp)
      else
        if size(run) > 0
          items.push([x, run])
          x += text_width(run) + 1
          run = ""
        end
        var g = self.glyph(cp)
        items.push([x, g != nil ? g : BOX])
        x += 8
      end
    end
    if size(run) > 0
      items.push([x, run])
      x += text_width(run)
    end
    return [x, items]
  end

  def msg(s)
    var l = self.msgs.find(s)
    if l == nil
      l = self.layout(s)
      self.msgs[s] = l
    end
    return l
  end

  # Draw a laid-out line with its top at y, shifted left by off, kept left of column clip
  def draw_line(lay, x0, y, off, c, clip)
    for it:lay[1]
      var x = x0 + it[0] - off
      if x >= clip continue end
      var g = it[1]
      if type(g) == "string"
        text(x, y + 6, g, c)
      elif x > -8
        for r:0..6
          var b = g[r]
          if b != 0
            for k:0..7
              if (b & (0x80 >> k)) != 0
                var px = x + k
                if px >= 0 && px < clip pixel(px, y + r, c) end
              end
            end
          end
        end
      end
    end
  end

  # ---------- data ----------

  def fetch()
    if size(self.ids) == 0 return end
    self.busy = true
    self.busy_at = now_ms()
    http.post(LIVE_URL, json.dump({'station_no': self.ids}), / b, st -> self.on_body(b, st),
              {'headers': {'Content-Type': "application/json"}, 'timeout': 15})
  end

  def retry()
    self.fail += 1
    var w = 15000
    var k = 1
    while k < self.fail && w < self.every
      w *= 2
      k += 1
    end
    if w > self.every w = self.every end
    self.next_at = now_ms() + w
  end

  def on_body(b, st)
    self.busy = false
    var d = st == 200 && b != nil ? json.load(b) : nil
    var rv = isinstance(d, map) ? d.find("retVal") : nil
    var arr = isinstance(rv, map) ? rv.find("data") : nil
    if !isinstance(arr, list)
      self.err = st == 200 ? "資料錯誤" : "連線失敗"
      self.retry()
      return
    end
    var m = {}
    for s:arr
      if !isinstance(s, map) continue end
      var det = s.find("available_spaces_detail")
      var eb = isinstance(det, map) ? det.find("eyb", 0) : 0
      m[str(s.find("station_no", ""))] = [int(s.find("available_spaces", 0)), int(eb == nil ? 0 : eb),
                                         int(s.find("empty_spaces", 0)), int(s.find("status", 1))]
    end
    self.rows = m
    self.err = nil
    self.fail = 0
    self.ok_at = now_ms()
    self.next_at = now_ms() + self.every
  end

  def refresh_now()
    self.poke = now_ms()
    if self.busy return end
    self.fail = 0
    self.next_at = 0
  end

  def loop()
    var t = now_ms()
    if self.busy
      if t - self.busy_at > 40000
        self.busy = false
        self.err = "連線失敗"
        self.retry()
      end
      return
    end
    if t >= self.next_at self.fetch() end
  end

  # ---------- app hooks ----------

  def should_show() return true end

  def page_ms(i)
    var l = i < size(self.lays) ? self.lays[i] : nil
    if l == nil || l[0] <= 50 return self.per end
    var need = 1200 + (l[0] - 50) * 1000 / 16 + 1500
    return need > self.per ? need : self.per
  end

  def duration()
    var n = size(self.ids)
    if n == 0 return 5000 end
    var s = 0
    for i:0..n - 1 s += self.page_ms(i) end
    return s
  end

  def on_show()
    self.since = now_ms()
    self.cur = 0
    if self.ok_at > 0 && now_ms() - self.ok_at > 60000 self.refresh_now() end
  end

  def on_button(btn)
    if btn == "select"
      self.refresh_now()
      return true
    end
    return false
  end

  def on_button_event(btn, ev)
    if btn == "select" && ev == "press"
      self.refresh_now()
      return true
    end
    return false
  end

  def on_knob(ev)
    var n = size(self.ids)
    if ev == "press"
      self.refresh_now()
      return true
    end
    if n <= 1 return false end
    if ev == "right" self.cur = (self.cur + 1) % n
    elif ev == "left" self.cur = (self.cur - 1 + n) % n
    else return false end
    self.since = now_ms()
    return true
  end

  # ---------- drawing ----------

  def draw_bike(x0, y0, c)
    for y:0..6
      for x:self.bike[y]
        pixel(x0 + x, y0 + y, c)
      end
    end
  end

  def draw()
    clear()
    var t = now_ms()
    var n = size(self.ids)
    if n == 0
      self.draw_bike(0, 5, YB)
      self.draw_line(self.msg("請設定站點"), 12, 4, 0, YB, 52)
      return
    end
    if self.cur >= n self.cur = 0 end
    if t - self.since >= self.page_ms(self.cur)
      self.cur = (self.cur + 1) % n
      self.since = t
    end
    var i = self.cur
    var id = self.ids[i]

    # Top: station name (scrolls when longer than 50 px)
    if self.lays[i] == nil
      self.lays[i] = self.layout(size(self.names[i]) > 0 ? self.names[i] : (size(id) > 4 ? "#" + id[size(id) - 4 ..] : id))
    end
    var lay = self.lays[i]
    var off = 0
    if lay[0] > 50
      var el = t - self.since - 1200
      off = el > 0 ? el * 16 / 1000 : 0
      if off > lay[0] - 50 off = lay[0] - 50 end
    end
    self.draw_line(lay, 0, 0, off, self.ink, 50)
    rect_fill(50, 0, 2, 8, 0)

    # Right edge: which station (red thumb = last update failed)
    if n > 1 || self.err != nil
      rect_fill(51, 0, 1, 8, TRACK)
      var h = 8 / n
      if h < 2 h = 2 end
      var y = n > 1 ? i * (8 - h) / (n - 1) : 0
      rect_fill(51, y, 1, h, self.err != nil ? RED : YB)
    end

    # Bottom: bike (rides while updating), bikes, e-bikes, free docks
    var riding = self.busy || t - self.poke < 700
    var bx = riding ? (t / 120) % 2 : 0
    var r = self.rows.find(id)
    if r == nil
      self.draw_bike(bx, 9, 0x606060)
      var m = self.ok_at > 0 ? "查無此站" : (self.err != nil ? self.err : "載入中")
      self.draw_line(self.msg(m), 13, 9, 0, self.ok_at > 0 || self.err != nil ? ORANGE : GRAY, 52)
      return
    end
    if r[3] != 1
      self.draw_bike(bx, 9, 0x606060)
      self.draw_line(self.msg("暫停營運"), 13, 9, 0, ORANGE, 52)
      return
    end
    self.draw_bike(bx, 9, YB)
    var bikes = r[0]
    var c = bikes == 0 ? RED : (bikes < self.low ? ORANGE : self.ink)
    font("large")
    var x = 13 + text(13, 15, str(bikes), c)
    font("small")
    if self.ebike && r[1] > 0
      x += 2
      pixel(x + 1, 10, YB) pixel(x, 11, YB) pixel(x, 12, YB) pixel(x + 1, 12, YB)
      pixel(x + 1, 13, YB) pixel(x, 14, YB)
      text(x + 3, 15, str(r[1]), YB)
    end
    var ds = str(r[2])
    var dx = 52 - text_width(ds)
    text(dx, 15, ds, GRAY)
    text(dx - 5, 15, "P", BLUE)
  end
end
return YouBikeTW()
