############
## Settings
############

$out_file = "./zpl.out"
$printer_name = "ZebraLabelTest"

$label_settings = [PSCustomObject]@{
    mode  = 2    # enhanced
    mag   = 4   # 1-10
    top   = 20
    left  = 230
    text = [PSCustomObject]@{
        font    = "S"  # OCR All CAPS
        top     = 150
        left    = 110
        scale_h = 36   # Must maintain ratio
        scale_w = 20   # (36/20) (24/15) (18/10) (12/5)
    }
    logo = [PSCustomObject]@{
        draw  = 1
        top   = 40
        left  = 90
        ascii = ",1235,1235,13,FF8,JF,C07FF8,CI0FF8,CJ07F8,CK07F,6L07E,6M0F8,6M01F,6N07C,6O0F,3O03C,3P0F,3P03C,3Q0E,18P078,18P01E,18Q0F,0CQ038,0CQ01E,0CR07,06K07FK038,06J01FFCJ01C,07J07IFK0F,03J07F7F8J038,03J0F80F8J01C,018I0F007CK0E,018001E003CK07,00C001E001EK03IF8,00C001E001EK01KF8,006001E001EL0E003F8,006001E001EL06I01C,003I0E001EL07J0C,003I0F001CL03J0E,001800F803CL018I06,001C007C07CM0CI06,I0C003F9F8M06I03,I06001IFN06I03,I07I0FFEN03I018,I03I03FCN0180018,I038S018001C,I01CT0CI0C,J0CM038K06I0C,J06M07CK06I06,J07M07EK03I06,J038L0CFK03I03,J018K018F8J018003,K0CK0186CJ0180038,K0EK03066K0C0018,K07K01823K0C0018,K038J01831CJ06I0C,K01CK0C18EJ06I0C,L0EK061C7J02I06,L06K060E38I03I06,L03K03070CI07FFC7,L018J030186001KF,M0CJ0180C30038003F,M07K0C07180F,M038J07038E1C,M01CJ0381C738,N0EK0C063F,N07K07031E,N038J0381CE,N03CJ01C0E6,N03FK06076,N0338J0383F,N031CJ01C0F,N0307K0E07,N03038J0707,N0300EJ0FC6,N03007I01CEC,N03001C00187C,N03I0E003038,N03I03807,N03I01E06,N03J070C,N03J01CC,N03K078,N03K018,:N018J018,N018K0C,N01EK0C,O0F8J0C,O03EJ0C,P0F8I0C,P03EI0C,Q07800C,Q01F00C,R07C0C,R01F0C,S07CC,T0FC,T03C,U0C,"
    }
    #"^FO10,210^GB385,2,2^FS"
    line = [PSCustomObject]@{
        draw      = 1
        top       = 210
        left      = 10
        width     = 385
        height    = 2
        thickness = 2
        color     = "B" # W/B
        rounding  = 0   # 0-8
    }
}


. .\ZebraLabel.ps1

## Function to build QR Label
function BuildZPL-QR {

    param (
        $settings,
        $Value,
        $Text
    )

    $QR_Top        = $settings.top
    $QR_Left       = $settings.left
    $QR_Mode       = $settings.mode
    $QR_Mag        = $settings.mag
    $Text_Top      = $settings.text.top
    $Text_Left     = $settings.text.left
    $Text_Font     = $settings.text.font
    $Img_Top       = $settings.logo.top
    $Img_Left      = $settings.logo.left
    $Img_Logo      = $settings.logo.ascii
    $Box_Top       = $settings.line.top
    $Box_Left      = $settings.line.left
    $Box_Width     = $settings.line.width
    $Box_Height    = $settings.line.height
    $Box_Thickness = $settings.line.thickness
    $Box_Color     = $settings.line.color 
    $Box_Rounding  = $settings.line.rounding

    $label = [ZebraLabel]::New()
    $label.Logo($Img_Top, $Img_Left, $Img_Logo)
    $label.SetFont($Text_Font)
    $label.Location($QR_Top, $QR_Left)
    $label.QRCode($QR_Mode, $QR_Mag, "$Value")
    $label.Location($Text_Top, $Text_Left)
    $label.Text($Text)
    $label.Box($Box_Left, $Box_Top, $Box_Width, $Box_Height, $Box_Thickness, $Box_Color, $Box_Rounding)
    $label.EndZPL()
    $label.ToFile($out_file)
    Write-Host $label.Get_Label()
    return

}

$qr_text = "This is QR Code text."
$label_text = "This is a Label"

BuildZPL-QR $label_settings $qr_text $label_text


