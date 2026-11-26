# plymouth.nix by poligle

# passphrase: what the disk's password is called, in the system's language (theme/i18n.nix). It's
# shown instead of what asks for it: systemd-cryptsetup's words are English, whatever the language.
{ pkgs, waitForSound ? false, passphrase ? "Disk passphrase", wallpaper ? null }:
let
  python = pkgs.python3.withPackages (ps: [ ps.pillow ]);

  # When a wallpaper is given, the boot animation and its text are tinted with
  # that picture's average colour instead of a fixed grey.
  inkFile = if wallpaper == null then null else pkgs.runCommand "btechos-wallpaper-ink"
  {
      nativeBuildInputs = [ pkgs.imagemagick pkgs.gawk ];
  } ''
      means=$(magick ${wallpaper} -resize '64x64!' \
          -format '%[fx:mean.r],%[fx:mean.g],%[fx:mean.b]' info:)
      awk -F, '{ m = $1; if ($2 > m) m = $2; if ($3 > m) m = $3;
          printf "%.3f,%.3f,%.3f\n", $1/m, $2/m, $3/m }' <<< "$means" > $out
  '';

  ink = if inkFile == null then "0.949, 0.949, 0.949" else "__INK__";
  intro = 36;
  loop = 60;

  script = pkgs.writeText "btechos.script" ''
    baseline_y = 0;
    message_y = 0;

    fun layout () {
      screen = 0;
      shortest = 0;
      while (Window.GetWidth(screen)) {
        Window.SetX(screen, Math.Int(0 - Window.GetWidth(screen) / 2));
        Window.SetY(screen, Math.Int(0 - Window.GetHeight(screen) / 2));
        if (shortest == 0) {
          shortest = Window.GetHeight(screen);
        }
        if (Window.GetHeight(screen) < shortest) {
          shortest = Window.GetHeight(screen);
        }
        screen++;
      }
      baseline_y = shortest * 0.4;
      message_y = shortest * 0.25;
    }

    layout();
    center_x = 0;
    center_y = 0;

    Window.SetBackgroundTopColor(0, 0, 0);
    Window.SetBackgroundBottomColor(0, 0, 0);

    logo.static = Image("logo.png");
    for (i = 0; i < ${toString (intro + loop)}; i++) {
      logo.frames[i] = Image("frame-" + i + ".png");
    }

    logo.sprite = Sprite(logo.frames[0]);
    logo.sprite.SetPosition(
      center_x - (logo.static.GetWidth() / 2),
      center_y - (logo.static.GetHeight() / 2),
      1
    );

    logo.animated = 1;
    logo.tick = 0;

    logo.opened = 1;
    if (${if waitForSound then "1" else "0"}) {
      if (Plymouth.GetMode() == "boot") {
        logo.opened = 0;
      }
    }
    logo.waited = 0;

    fun open_logo () {
      if (logo.opened == 0) {
        logo.opened = 1;
        logo.tick = 0;
      }
    }

    fun status_callback (status) {
      if (status == "btechos-open") {
        open_logo();
      }
    }

    Plymouth.SetUpdateStatusFunction(status_callback);

    fun refresh_callback () {
      layout();
      if (logo.animated) {
        if (logo.opened == 0) {
          logo.waited++;
          if (logo.waited > 500) {
            open_logo();
          }
        }
        if (logo.opened) {
          step = Math.Int(logo.tick / 2);
          if (step < ${toString intro}) {
            frame_index = step;
          } else {
            frame_index = ${toString intro} + ((step - ${toString intro}) % ${toString loop});
          }
          logo.sprite.SetImage(logo.frames[frame_index]);
          logo.tick++;
        } else {
          logo.sprite.SetImage(logo.frames[0]);
        }
      }
    }

    fun stop_animation () {
      logo.animated = 0;
      if (logo.opened) {
        logo.sprite.SetImage(logo.static);
      } else {
        logo.sprite.SetImage(logo.frames[0]);
      }
    }

    fun start_animation () {
      logo.animated = 1;
    }

    Plymouth.SetRefreshFunction(refresh_callback);

    prompt = null;
    bullets = null;
    bullet.image = Image.Text("•", ${ink});

    fun password_callback (prompt_text, bullet_count) {
      stop_animation();

      prompt.image = Image.Text(${builtins.toJSON passphrase}, ${ink});
      prompt.sprite = Sprite(prompt.image);
      prompt.sprite.SetPosition(
        center_x - (prompt.image.GetWidth() / 2),
        baseline_y - prompt.image.GetHeight(),
        1
      );

      total_width = bullet_count * bullet.image.GetWidth();
      start_x = center_x - (total_width / 2);

      bullets = null;
      for (i = 0; i < bullet_count; i++) {
        bullets[i].sprite = Sprite(bullet.image);
        bullets[i].sprite.SetPosition(
          start_x + (i * bullet.image.GetWidth()),
          baseline_y + bullet.image.GetHeight(),
          1
        );
      }
    }

    Plymouth.SetDisplayPasswordFunction(password_callback);

    question = null;
    answer = null;

    fun question_callback (prompt_text, entry) {
      stop_animation();

      question = null;
      answer = null;

      question.image = Image.Text(prompt_text, ${ink});
      question.sprite = Sprite(question.image);
      question.sprite.SetPosition(
        center_x - (question.image.GetWidth() / 2),
        baseline_y - question.image.GetHeight(),
        1
      );

      answer.image = Image.Text(entry, ${ink});
      answer.sprite = Sprite(answer.image);
      answer.sprite.SetPosition(
        center_x - (answer.image.GetWidth() / 2),
        baseline_y + answer.image.GetHeight(),
        1
      );
    }

    Plymouth.SetDisplayQuestionFunction(question_callback);

    message = null;

    fun message_callback (text) {
      message.image = Image.Text(text, ${ink});
      message.sprite = Sprite(message.image);
      message.sprite.SetPosition(
        center_x - message.image.GetWidth() / 2,
        message_y,
        1
      );
    }

    Plymouth.SetMessageFunction(message_callback);

    fun normal_callback () {
      prompt = null;
      bullets = null;

      question = null;
      answer = null;

      message = null;

      start_animation();
    }

    Plymouth.SetDisplayNormalFunction(normal_callback);

    fun quit_callback () {
      prompt = null;
      bullets = null;
      stop_animation();
    }

    Plymouth.SetQuitFunction(quit_callback);
  '';
in
pkgs.runCommand "btechos-plymouth" { nativeBuildInputs = [ python pkgs.gawk ]; } ''
  dir="$out/share/plymouth/themes/btechos"
  mkdir -p "$dir"

  tint="${if inkFile == null then "1,1,1" else "$(cat ${inkFile})"}"
  python3 ${./plymouth.py} ${./art/snowflake-29.txt} "$dir" --tint "$tint"

  # Plymouth's Image.Text wants components in 0..1; keep the old brightness
  # while taking the hue from the wallpaper.
  text=$(awk -F, -v s=0.949 '{ printf "%s, %s, %s", $1*s, $2*s, $3*s }' <<< "$tint")
  sed "s/__INK__/$text/g" ${script} > "$dir/btechos.script"
  {
    printf '[Plymouth Theme]\n'
    printf 'Name=BTechOS\n'
    printf 'Description=ex btechoso\n'
    printf 'ModuleName=script\n\n'
    printf '[script]\n'
    printf 'ImageDir=%s\n' "$dir"
    printf 'ScriptFile=%s\n' "$dir/btechos.script"
  } > "$dir/btechos.plymouth"
''
